import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Verifies server-signed commercial entitlements.
///
/// The corresponding private key must never be included in the app.
class CommercialEntitlementVerifier {
  CommercialEntitlementVerifier._();

  static const String issuer = 'creator-yard-email-api';
  static const String product = 'creator-yard-inventory';

  // Raw 32-byte Ed25519 public key, encoded as standard Base64.
  static const String _publicKeyBase64 =
      'wIRPZIfiiS04rNmyEUXmCuMQx3GoKt+QZclr0fNNwQA=';

  static final Ed25519 _algorithm = Ed25519();

  /// Token format: base64url(payload JSON bytes).base64url(signature).
  ///
  /// The signature is verified over the original payload bytes, before JSON
  /// parsing, to avoid signing/verification canonicalization differences.
  static Future<Map<String, dynamic>?> verify({
    required String token,
    required String expectedInstallationId,
    String? testPublicKeyBase64,
  }) async {
    try {
      final parts = token.split('.');
      if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
        return null;
      }

      final payloadBytes = _decodeBase64Url(parts[0]);
      final signatureBytes = _decodeBase64Url(parts[1]);

      if (payloadBytes == null ||
          signatureBytes == null ||
          signatureBytes.length != 64) {
        return null;
      }

      //final publicKeyBytes = base64Decode(_publicKeyBase64);
      final publicKeyBytes = base64Decode(
        testPublicKeyBase64 ?? _publicKeyBase64,
      );
      if (publicKeyBytes.length != 32) {
        return null;
      }

      final publicKey = SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.ed25519,
      );

      final signature = Signature(signatureBytes, publicKey: publicKey);

      final signatureIsValid = await _algorithm.verify(
        payloadBytes,
        signature: signature,
      );

      if (!signatureIsValid) {
        return null;
      }

      final decoded = jsonDecode(utf8.decode(payloadBytes));
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      if (decoded['issuer'] != issuer ||
          decoded['product'] != product ||
          decoded['installationId'] != expectedInstallationId ||
          decoded['status'] != 'active') {
        return null;
      }

      final issuedAtValue = decoded['issuedAt'];
      final expiresAtValue = decoded['expiresAt'];
      if (issuedAtValue is! String || expiresAtValue is! String) {
        return null;
      }

      final issuedAt = DateTime.tryParse(issuedAtValue)?.toUtc();
      final expiresAt = DateTime.tryParse(expiresAtValue)?.toUtc();
      if (issuedAt == null || expiresAt == null) {
        return null;
      }

      final now = DateTime.now().toUtc();
      const maxOfflineValidity = Duration(days: 30);

      if (issuedAt.isAfter(now) ||
          !expiresAt.isAfter(issuedAt) ||
          expiresAt.difference(issuedAt) > maxOfflineValidity ||
          !expiresAt.isAfter(now)) {
        return null;
      }

      return decoded;
    } catch (_) {
      // Malformed tokens and verification failures must never grant access.
      return null;
    }
  }

  static List<int>? _decodeBase64Url(String value) {
    try {
      return base64Url.decode(base64Url.normalize(value));
    } catch (_) {
      return null;
    }
  }
}
