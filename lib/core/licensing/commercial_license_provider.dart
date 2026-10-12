// lib/core/licensing/commercial_license_provider.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../database/business_settings.dart';
import '../../database/daos/settings_dao.dart';
import '../system/installation_identity.dart';
import 'commercial_entitlement_verifier.dart';
import 'license_provider.dart';
import 'license_state.dart';

typedef EntitlementVerifier =
    Future<Map<String, dynamic>?> Function({
      required String token,
      required String expectedInstallationId,
    });

/// Server-backed commercial licensing provider.
///
/// The Worker is the commercial licensing authority. This provider never
/// activates or modifies a license. A signed entitlement is required before
/// commercial access is granted, and verified entitlements are cached for
/// offline use.
class CommercialLicenseProvider implements LicenseProvider {
  CommercialLicenseProvider({
    required this.settingsDao,
    this._httpClient,
    String? baseUrl,
    Future<String> Function(SettingsDao)? installationIdProvider,
    EntitlementVerifier? entitlementVerifier,
  }) : _baseUrl = baseUrl ?? _productionBaseUrl,
       _installationIdProvider =
           installationIdProvider ?? InstallationIdentity.getInstallationId,
       _entitlementVerifier =
           entitlementVerifier ?? CommercialEntitlementVerifier.verify;

  static const String _productionBaseUrl =
      'https'
      ':'
      '/'
      '/'
      'creator-yard-email-api.dawn-feather-6cd6.workers.dev';

  static const Duration _requestTimeout = Duration(seconds: 10);

  final SettingsDao settingsDao;
  final http.Client? _httpClient;
  final String _baseUrl;
  final Future<String> Function(SettingsDao) _installationIdProvider;
  final EntitlementVerifier _entitlementVerifier;

  @override
  Future<LicenseState> initialize() async {
    final installationId = await _installationIdProvider(settingsDao);

    // Verify the cached entitlement, but do not let it override an online
    // server decision when the server is reachable.
    final cachedToken = await settingsDao.getSetting(
      BusinessSettings.commercialEntitlement,
    );

    Map<String, dynamic>? cachedClaims;
    if (cachedToken != null && cachedToken.trim().isNotEmpty) {
      cachedClaims = await _entitlementVerifier(
        token: cachedToken,
        expectedInstallationId: installationId,
      );

      if (cachedClaims == null) {
        await settingsDao.setSetting(
          BusinessSettings.commercialEntitlement,
          '',
        );
      }
    }

    LicenseState offlineFallback() {
      if (cachedClaims != null) {
        return _licensedState(installationId);
      }
      return _verificationUnavailableState(installationId);
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl/v1/licensing/status'
        '?installationId=${Uri.encodeQueryComponent(installationId)}',
      );

      final client = _httpClient;
      final response = await (client == null ? http.get(uri) : client.get(uri))
          .timeout(_requestTimeout);

      // A failed or malformed server response is not proof of revocation.
      // Continue using a valid, unexpired cache if one exists.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return offlineFallback();
      }

      final responseData = jsonDecode(response.body);
      if (responseData is! Map<String, dynamic> ||
          responseData['success'] != true) {
        return offlineFallback();
      }

      // An authoritative response must distinguish absence from revocation.
      if (responseData['licensed'] == false) {
        if (!responseData.containsKey('license')) {
          // An incomplete response is not proof of license absence.
          return offlineFallback();
        }

        final licenseRecord = responseData['license'];

        if (licenseRecord == null) {
          await settingsDao.setSetting(
            BusinessSettings.commercialEntitlement,
            '',
          );
          return _noCommercialLicenseState(installationId);
        }

        if (licenseRecord is! Map || licenseRecord['status'] == 'active') {
          // An inconsistent response is not proof of license absence.
          return offlineFallback();
        }

        // Any authoritative non-active record overrides the cached entitlement.
        await settingsDao.setSetting(
          BusinessSettings.commercialEntitlement,
          '',
        );
        return _unlicensedState(installationId);
      }

      if (responseData['licensed'] != true) {
        return offlineFallback();
      }

      final token = responseData['entitlement'];
      if (token is! String || token.trim().isEmpty) {
        return offlineFallback();
      }

      final claims = await _entitlementVerifier(
        token: token,
        expectedInstallationId: installationId,
      );

      if (claims == null) {
        return offlineFallback();
      }

      // Persist only an entitlement that passes signature and expiry checks.
      await settingsDao.setSetting(
        BusinessSettings.commercialEntitlement,
        token,
      );

      return _licensedState(installationId);
    } catch (_) {
      // Network errors must not invalidate an otherwise valid offline token.
      return offlineFallback();
    }
  }

  @override
  Future<bool> hasAccess() async {
    final state = await initialize();
    return state.hasAccess;
  }

  LicenseState _licensedState(String installationId) {
    return LicenseState(
      status: LicenseStatus.licensed,
      installationId: installationId,
    );
  }

  LicenseState _noCommercialLicenseState(String installationId) {
    return LicenseState(
      status: LicenseStatus.noCommercialLicense,
      installationId: installationId,
    );
  }

  LicenseState _unlicensedState(String installationId) {
    return LicenseState(
      status: LicenseStatus.unlicensed,
      installationId: installationId,
    );
  }

  LicenseState _verificationUnavailableState(String installationId) {
    return LicenseState(
      status: LicenseStatus.verificationUnavailable,
      installationId: installationId,
    );
  }
}
