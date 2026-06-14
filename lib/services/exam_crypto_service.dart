import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// Decrypts the "sealed envelope" exam package produced by the backend
/// (`utils/examCrypto.js`). Format must stay in lockstep with that file:
/// PBKDF2-HMAC-SHA256 (key derivation) → AES-256-GCM (payload).
///
/// The envelope is opaque on the device until the student enters the exam
/// password the proctor announces at start time.
class ExamCryptoService {
  const ExamCryptoService._();

  /// Decrypt an envelope map into the original payload object.
  /// Throws [ExamDecryptException] when the password is wrong or data is
  /// corrupt (GCM authentication failure).
  static Future<Map<String, dynamic>> decryptPayload(
    Map<String, dynamic> envelope,
    String password,
  ) async {
    try {
      final salt = base64Decode(envelope['salt'] as String);
      final iv = base64Decode(envelope['iv'] as String);
      final authTag = base64Decode(envelope['auth_tag'] as String);
      final ciphertext = base64Decode(envelope['ciphertext'] as String);
      final iterations = envelope['iterations'] as int? ?? 210000;

      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: 256,
      );
      final secretKey = await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      );

      final algorithm = AesGcm.with256bits();
      final clearBytes = await algorithm.decrypt(
        SecretBox(ciphertext, nonce: iv, mac: Mac(authTag)),
        secretKey: secretKey,
      );

      final decoded = jsonDecode(utf8.decode(clearBytes));
      return Map<String, dynamic>.from(decoded as Map);
    } on SecretBoxAuthenticationError {
      // Wrong password or tampered data - GCM tag mismatch.
      throw const ExamDecryptException('Password salah atau paket ujian rusak');
    } catch (_) {
      throw const ExamDecryptException('Gagal membuka paket ujian');
    }
  }
}

class ExamDecryptException implements Exception {
  final String message;
  const ExamDecryptException(this.message);
  @override
  String toString() => message;
}
