import 'package:encrypt/encrypt.dart';

/// AES encryption service for sensitive Firestore data.
///
/// Uses AES-CBC with a fixed 32-byte key and 16-byte IV.
/// The IV is prepended to the ciphertext so decryption
/// can recover it automatically.
class EncryptionService {
  // 32-byte secret key for AES-256 (EXACTLY 32 characters)
  static const String _secretKey = 'HealthyBhai2026!EncryptKey#AES32';

  /// Encrypts a plain-text string.
  /// Returns a base64 string in the format:  IV_base64:Ciphertext_base64
  static String encryptData(String plainText) {
    if (plainText.isEmpty) return plainText;

    final key = Key.fromUtf8(_secretKey);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts a previously encrypted string.
  /// If the input doesn't look encrypted (no ':'), returns it as-is
  /// so old unencrypted data still works.
  static String decryptData(String cipherText) {
    if (cipherText.isEmpty) return cipherText;

    // If there's no ':', this is likely plain (unencrypted) data — return as-is
    if (!cipherText.contains(':')) return cipherText;

    try {
      final parts = cipherText.split(':');
      final ivBase64 = parts[0];
      final encryptedBase64 = parts.sublist(1).join(':');

      final key = Key.fromUtf8(_secretKey);
      final iv = IV.fromBase64(ivBase64);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      return encrypter.decrypt64(encryptedBase64, iv: iv);
    } catch (_) {
      // If decryption fails, return original text (backward compatible)
      return cipherText;
    }
  }

  // ─── HELPERS FOR MAP ENCRYPTION ───

  /// Encrypts specific String fields in a Map.
  static Map<String, dynamic> encryptFields(
    Map<String, dynamic> data,
    List<String> fieldsToEncrypt,
  ) {
    final result = Map<String, dynamic>.from(data);
    for (final field in fieldsToEncrypt) {
      if (result.containsKey(field) && result[field] != null) {
        final value = result[field];
        if (value is String) {
          result[field] = encryptData(value);
        } else if (value is List) {
          // Encrypt each item in the list (e.g., allergies, medicines)
          result[field] = value.map((item) =>
            item is String ? encryptData(item) : item
          ).toList();
        }
      }
    }
    return result;
  }

  /// Decrypts specific String fields in a Map.
  static Map<String, dynamic> decryptFields(
    Map<String, dynamic> data,
    List<String> fieldsToDecrypt,
  ) {
    final result = Map<String, dynamic>.from(data);
    for (final field in fieldsToDecrypt) {
      if (result.containsKey(field) && result[field] != null) {
        final value = result[field];
        if (value is String) {
          result[field] = decryptData(value);
        } else if (value is List) {
          // Decrypt each item in the list
          result[field] = value.map((item) =>
            item is String ? decryptData(item) : item
          ).toList();
        }
      }
    }
    return result;
  }
}
