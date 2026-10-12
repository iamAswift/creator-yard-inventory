import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supermarket_inventory/core/licensing/commercial_license_provider.dart';
import 'package:supermarket_inventory/core/licensing/license_state.dart';
import 'package:supermarket_inventory/database/business_settings.dart';
import 'package:supermarket_inventory/database/daos/settings_dao.dart';

const installationId = 'test-installation-001';
const validToken = 'test-valid-entitlement';
const invalidToken = 'test-invalid-entitlement';

class FakeSettingsDao implements SettingsDao {
  final Map<String, String> values = {};

  @override
  Future<String?> getSetting(String key) async => values[key];

  @override
  Future<void> setSetting(String key, String value) async {
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<Map<String, dynamic>?> fakeVerifier({
  required String token,
  required String expectedInstallationId,
}) async {
  if (token != validToken || expectedInstallationId != installationId) {
    return null;
  }

  return <String, dynamic>{
    'issuer': 'creator-yard-email-api',
    'product': 'creator-yard-inventory',
    'installationId': installationId,
    'status': 'active',
  };
}

http.Response response(Map<String, dynamic> body, {int status = 200}) {
  return http.Response(jsonEncode(body), status);
}

void main() {
  late FakeSettingsDao settings;

  setUp(() {
    settings = FakeSettingsDao();
  });

  CommercialLicenseProvider createProvider(
    MockClient client, {
    EntitlementVerifier? verifier,
  }) {
    return CommercialLicenseProvider(
      settingsDao: settings,
      baseUrl: 'https://licensing.test',
      httpClient: client,
      installationIdProvider: (_) async => installationId,
      entitlementVerifier: verifier ?? fakeVerifier,
    );
  }

  group('CommercialLicenseProvider', () {
    test('accepts and caches a valid online entitlement', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/v1/licensing/status');
        expect(request.url.queryParameters['installationId'], installationId);
        return response({
          'success': true,
          'licensed': true,
          'entitlement': validToken,
        });
      });

      final state = await createProvider(client).initialize();

      expect(state.status, LicenseStatus.licensed);
      expect(state.hasAccess, isTrue);
      expect(
        settings.values[BusinessSettings.commercialEntitlement],
        validToken,
      );

      client.close();
    });

    test('confirmed revocation clears cached entitlement', () async {
      settings.values[BusinessSettings.commercialEntitlement] = validToken;

      final client = MockClient((_) async {
        return response({
          'success': true,
          'licensed': false,
          'license': {'status': 'revoked', 'revoked_at': '2026-10-01 10:00:00'},
        });
      });

      final state = await createProvider(client).initialize();

      expect(state.status, LicenseStatus.unlicensed);
      expect(state.hasAccess, isFalse);
      expect(settings.values[BusinessSettings.commercialEntitlement], '');

      client.close();
    });

    test('non-active license status clears cached entitlement', () async {
      settings.values[BusinessSettings.commercialEntitlement] = validToken;

      final client = MockClient((_) async {
        return response({
          'success': true,
          'licensed': false,
          'license': {'status': 'suspended'},
        });
      });

      final state = await createProvider(client).initialize();

      expect(state.status, LicenseStatus.unlicensed);
      expect(state.hasAccess, isFalse);
      expect(settings.values[BusinessSettings.commercialEntitlement], '');

      client.close();
    });

    test('no commercial record is distinct from revocation', () async {
      settings.values[BusinessSettings.commercialEntitlement] = validToken;

      final client = MockClient((_) async {
        return response({'success': true, 'licensed': false, 'license': null});
      });

      final state = await createProvider(client).initialize();

      expect(state.status, LicenseStatus.noCommercialLicense);
      expect(state.hasAccess, isFalse);
      expect(settings.values[BusinessSettings.commercialEntitlement], '');

      client.close();
    });

    test('uses valid cached entitlement when network fails', () async {
      settings.values[BusinessSettings.commercialEntitlement] = validToken;

      final client = MockClient((_) async {
        throw Exception('simulated offline');
      });

      final state = await createProvider(client).initialize();

      expect(state.status, LicenseStatus.licensed);
      expect(state.hasAccess, isTrue);
      expect(
        settings.values[BusinessSettings.commercialEntitlement],
        validToken,
      );

      client.close();
    });

    test('clears invalid cache and denies access when offline', () async {
      settings.values[BusinessSettings.commercialEntitlement] = invalidToken;

      final client = MockClient((_) async {
        throw Exception('simulated offline');
      });

      final state = await createProvider(client).initialize();

      expect(state.status, LicenseStatus.verificationUnavailable);
      expect(state.hasAccess, isFalse);
      expect(settings.values[BusinessSettings.commercialEntitlement], '');

      client.close();
    });

    test('server errors retain a valid cached entitlement', () async {
      settings.values[BusinessSettings.commercialEntitlement] = validToken;

      final client = MockClient((_) async {
        return response({'error': 'temporary failure'}, status: 503);
      });

      final state = await createProvider(client).initialize();

      expect(state.status, LicenseStatus.licensed);
      expect(state.hasAccess, isTrue);
      expect(
        settings.values[BusinessSettings.commercialEntitlement],
        validToken,
      );

      client.close();
    });

    test('rejects invalid online entitlement and does not cache it', () async {
      final client = MockClient((_) async {
        return response({
          'success': true,
          'licensed': true,
          'entitlement': invalidToken,
        });
      });

      final state = await createProvider(client).initialize();

      expect(state.status, LicenseStatus.verificationUnavailable);
      expect(state.hasAccess, isFalse);
      expect(
        settings.values.containsKey(BusinessSettings.commercialEntitlement),
        isFalse,
      );

      client.close();
    });

    test(
      'invalid online entitlement falls back to valid cached token',
      () async {
        settings.values[BusinessSettings.commercialEntitlement] = validToken;

        final client = MockClient((_) async {
          return response({
            'success': true,
            'licensed': true,
            'entitlement': invalidToken,
          });
        });

        final state = await createProvider(client).initialize();

        expect(state.status, LicenseStatus.licensed);
        expect(state.hasAccess, isTrue);
        expect(
          settings.values[BusinessSettings.commercialEntitlement],
          validToken,
        );

        client.close();
      },
    );

    test('malformed server response uses valid cached entitlement', () async {
      settings.values[BusinessSettings.commercialEntitlement] = validToken;

      final client = MockClient((_) async {
        return http.Response('not-json', 200);
      });

      final state = await createProvider(client).initialize();

      expect(state.status, LicenseStatus.licensed);
      expect(state.hasAccess, isTrue);

      client.close();
    });
  });
}
