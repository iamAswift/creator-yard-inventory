//lib/core/system/installation_registration_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../database/business_settings.dart';
import '../../database/daos/settings_dao.dart';

import 'installation_identity.dart';

class InstallationRegistrationService {
  InstallationRegistrationService._();

  static const String _baseUrl =
      'https://creator-yard-email-api.dawn-feather-6cd6.workers.dev';

  /// Registers this Creator Yard installation with the backend.
  ///
  /// The installation ID itself is generated and persisted locally by
  /// InstallationIdentity. This service synchronizes that ID and its
  /// installation credential with the Creator Yard backend.
  static Future<void> register(SettingsDao settingsDao) async {
    final installationId = await InstallationIdentity.getInstallationId(
      settingsDao,
    );

    final response = await http.post(
      Uri.parse('$_baseUrl/v1/installations/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'installationId': installationId}),
    );

    Map<String, dynamic> responseData;
    try {
      responseData = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw StateError(
        'Installation registration API returned an invalid response.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error =
          responseData['error']?.toString() ??
          'Installation registration failed.';
      throw StateError(error);
    }

    if (responseData['success'] != true) {
      final error =
          responseData['error']?.toString() ??
          'Installation registration failed.';
      throw StateError(error);
    }

    final installation = responseData['installation'] as Map<String, dynamic>?;

    final credential = installation?['credential']?.toString().trim();

    if (credential == null || credential.isEmpty) {
      throw StateError(
        'Installation registration API did not return an installation credential.',
      );
    }

    await settingsDao.setSetting(
      BusinessSettings.emailApiCredential,
      credential,
    );
  }
}
