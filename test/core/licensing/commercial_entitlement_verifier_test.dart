import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_inventory/core/licensing/commercial_entitlement_verifier.dart';

void main() {
  late Ed25519 algorithm;
  late SimpleKeyPair keyPair;
  late String publicKeyBase64;

  const installationId = 'test-installation-001';

  setUpAll(() async {
    algorithm = Ed25519();
    keyPair = await algorithm.newKeyPair();

    final publicKey = await keyPair.extractPublicKey();
    publicKeyBase64 = base64Encode(publicKey.bytes);
  });

  Future<String> createToken({
    DateTime? issuedAt,
    DateTime? expiresAt,
    String issuer = 'creator-yard-email-api',
    String product = 'creator-yard-inventory',
    String tokenInstallationId = installationId,
    String status = 'active',
  }) async {
    final now = DateTime.now().toUtc();
    final issued = (issuedAt ?? now).toUtc();
    final expires = (expiresAt ?? now.add(const Duration(days: 29))).toUtc();

    final payload = <String, dynamic>{
      'issuer': issuer,
      'product': product,
      'installationId': tokenInstallationId,
      'status': status,
      'issuedAt': issued.toIso8601String(),
      'expiresAt': expires.toIso8601String(),
    };

    final payloadBytes = utf8.encode(jsonEncode(payload));
    final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);

    String encodeUrl(List<int> bytes) =>
        base64Url.encode(bytes).replaceAll('=', '');

    return '${encodeUrl(payloadBytes)}.'
        '${encodeUrl(signature.bytes)}';
  }

  Future<Map<String, dynamic>?> verify(String token) {
    return CommercialEntitlementVerifier.verify(
      token: token,
      expectedInstallationId: installationId,
      testPublicKeyBase64: publicKeyBase64,
    );
  }

  group('CommercialEntitlementVerifier', () {
    test('accepts a valid signed entitlement', () async {
      final token = await createToken();

      final result = await verify(token);

      expect(result, isNotNull);
      expect(result!['status'], 'active');
      expect(result['installationId'], installationId);
    });

    test('rejects a modified payload', () async {
      final token = await createToken();
      final parts = token.split('.');
      final payload =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
              )
              as Map<String, dynamic>;

      payload['status'] = 'revoked';

      final modifiedPayload = base64Url
          .encode(utf8.encode(jsonEncode(payload)))
          .replaceAll('=', '');

      final result = await verify('$modifiedPayload.${parts[1]}');

      expect(result, isNull);
    });

    test('rejects a token with an invalid signature', () async {
      final token = await createToken();
      final parts = token.split('.');
      final invalidSignature = base64Url
          .encode(List<int>.filled(64, 0))
          .replaceAll('=', '');

      final result = await verify('${parts[0]}.$invalidSignature');

      expect(result, isNull);
    });

    test('rejects a malformed token', () async {
      expect(await verify('not-a-valid-token'), isNull);
      expect(await verify('a.b.c'), isNull);
      expect(await verify('.'), isNull);
    });

    test('rejects a different installation ID', () async {
      final token = await createToken(
        tokenInstallationId: 'another-installation',
      );

      expect(await verify(token), isNull);
    });

    test('rejects an incorrect issuer', () async {
      final token = await createToken(issuer: 'untrusted-issuer');

      expect(await verify(token), isNull);
    });

    test('rejects an incorrect product', () async {
      final token = await createToken(product: 'another-product');

      expect(await verify(token), isNull);
    });

    test('rejects a non-active entitlement', () async {
      final token = await createToken(status: 'revoked');

      expect(await verify(token), isNull);
    });

    test('rejects an expired entitlement', () async {
      final now = DateTime.now().toUtc();
      final token = await createToken(
        issuedAt: now.subtract(const Duration(days: 10)),
        expiresAt: now.subtract(const Duration(seconds: 1)),
      );

      expect(await verify(token), isNull);
    });

    test('rejects an issue time in the future', () async {
      final now = DateTime.now().toUtc();
      final token = await createToken(
        issuedAt: now.add(const Duration(minutes: 5)),
        expiresAt: now.add(const Duration(days: 10)),
      );

      expect(await verify(token), isNull);
    });

    test('rejects validity longer than 30 days', () async {
      final now = DateTime.now().toUtc();
      final token = await createToken(
        issuedAt: now,
        expiresAt: now.add(const Duration(days: 31)),
      );

      expect(await verify(token), isNull);
    });

    test('rejects expiry equal to issue time', () async {
      final now = DateTime.now().toUtc();
      final token = await createToken(issuedAt: now, expiresAt: now);

      expect(await verify(token), isNull);
    });
  });
}
