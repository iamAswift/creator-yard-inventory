// lib/core/licensing/commercial_license_provider.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../database/daos/settings_dao.dart';
import '../system/installation_identity.dart';
import 'license_provider.dart';
import 'license_state.dart';

/// Server-backed commercial licensing provider.
///
/// The Cloudflare Worker is the authority for commercial license state.
/// This provider never activates or modifies a license.
class CommercialLicenseProvider implements LicenseProvider {
  CommercialLicenseProvider({required this.settingsDao});

  static const String _baseUrl =
      'https' ':' '/' '/' 'creator-yard-email-api.dawn-feather-6cd6.workers.dev';

  static const Duration _requestTimeout = Duration(seconds: 10);

  final SettingsDao settingsDao;

  @override
  Future<LicenseState> initialize() async {
    final installationId =
        await InstallationIdentity.getInstallationId(settingsDao);

    try {
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/v1/licensing/status'
              '?installationId=${Uri.encodeQueryComponent(installationId)}',
            ),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _unlicensedState(installationId);
      }

      final responseData =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (responseData['success'] != true) {
        return _unlicensedState(installationId);
      }

      final licensed = responseData['licensed'] == true;

      if (!licensed) {
        return _unlicensedState(installationId);
      }

      return LicenseState(
        status: LicenseStatus.licensed,
        installationId: installationId,
      );
    } catch (_) {
      // Commercial access must fail closed if the licensing
      // authority cannot be reached or returns invalid data.
      return _unlicensedState(installationId);
    }
  }

  @override
  Future<bool> hasAccess() async {
    final state = await initialize();
    return state.hasAccess;
  }

  LicenseState _unlicensedState(String installationId) {
    return LicenseState(
      status: LicenseStatus.unlicensed,
      installationId: installationId,
    );
  }
}
