import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service to manage database encryption key securely
/// The key is stored in platform-specific secure storage:
/// - Android: Android Keystore
/// - iOS: Keychain
/// 
/// The database is encrypted using SQLCipher with AES-256 encryption.
/// The encryption key is stored securely and the database remains encrypted
/// both when the app is active and inactive.
class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const String _keyName = 'db_encryption_key';
  static const int _keyLength = 64; // 64 hex characters = 256 bits

  /// Get or generate encryption key
  /// If no key exists, generates a new one and stores it securely
  static Future<String> getEncryptionKey() async {
    try {
      // Try to get existing key
      String? key = await _storage.read(key: _keyName);
      
      if (key != null && key.isNotEmpty) {
        return key;
      }
      
      // Generate new key if none exists
      key = _generateEncryptionKey();
      await _storage.write(key: _keyName, value: key);
      return key;
    } catch (e) {
      // Fallback: generate a key (not ideal for production, but prevents crashes)
      // In production, you might want to handle this error more gracefully
      return _generateEncryptionKey();
    }
  }

  /// Generate a secure random encryption key
  /// SQLCipher uses this key to encrypt/decrypt the database
  /// Returns a 64-character hex string (256 bits) for AES-256 encryption
  static String _generateEncryptionKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(_keyLength ~/ 2, (i) => random.nextInt(256));
    final key = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return key;
  }

  /// Clear the encryption key (use with caution!)
  /// This will make the database unreadable until a new key is set
  static Future<void> clearEncryptionKey() async {
    await _storage.delete(key: _keyName);
  }

  /// Set a custom encryption key (for migration or testing)
  static Future<void> setEncryptionKey(String key) async {
    await _storage.write(key: _keyName, value: key);
  }
}

