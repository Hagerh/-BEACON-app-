import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

/// Service to manage persistent device ID
/// The device ID is stored securely and persists across app sessions
class DeviceIdService {
  static const _storage = FlutterSecureStorage();
  static const String _keyName = 'device_id';

  /// Get or generate a persistent device ID
  /// If no ID exists, generates a new one and stores it securely
  static Future<String> getDeviceId() async {
    try {
      // Try to get existing device ID
      String? deviceId = await _storage.read(key: _keyName);

      if (deviceId != null && deviceId.isNotEmpty) {
        return deviceId;
      }

      // Generate new device ID if none exists
      deviceId = _generateDeviceId();
      await _storage.write(key: _keyName, value: deviceId);
      return deviceId;
    } catch (e) {
     
      return _generateDeviceId();
    }
  }

  /// Generate a unique device ID
  /// Format: device_<timestamp>_<random>
  static String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'device_${timestamp}_$random';
  }

  /// Clear the stored device ID (use with caution!)
  /// This will generate a new ID on next app launch
  static Future<void> clearDeviceId() async {
    await _storage.delete(key: _keyName);
  }

  /// Set a custom device ID (for migration or testing)
  static Future<void> setDeviceId(String deviceId) async {
    await _storage.write(key: _keyName, value: deviceId);
  }
}
