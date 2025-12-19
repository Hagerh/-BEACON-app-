import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:projectdemo/data/local/database_helper.dart';

/// Service to manage persistent user ID
/// The user ID is stored securely and persists across app sessions
class UserIdService {
  static const _storage = FlutterSecureStorage();
  static const String _keyName = 'user_id';

  /// Get or create a persistent user ID
  /// If no ID exists, creates a new user and stores the ID securely
  static Future<int> getUserId() async {
    try {
      // Try to get existing user ID
      String? userIdStr = await _storage.read(key: _keyName);

      if (userIdStr != null && userIdStr.isNotEmpty) {
        final userId = int.tryParse(userIdStr);
        if (userId != null) {
          // Verify user still exists in database
          final db = DatabaseHelper.instance;
          final user = await db.getUserProfileById(userId);
          if (user != null) {
            return userId;
          }
        }
      }

      // No valid user ID found, create a new user
      final db = DatabaseHelper.instance;
      final userId = await db.createCurrentUser();
      await _storage.write(key: _keyName, value: userId.toString());
      return userId;
    } catch (e) {
      // Fallback: try to get/create user from database
      final db = DatabaseHelper.instance;
      final userId = await db.createCurrentUser();
      await _storage.write(key: _keyName, value: userId.toString());
      return userId;
    }
  }

  /// Clear the stored user ID (use with caution!)
  /// This will create a new user on next app launch
  static Future<void> clearUserId() async {
    await _storage.delete(key: _keyName);
  }

  /// Set a custom user ID (for migration or testing)
  static Future<void> setUserId(int userId) async {
    await _storage.write(key: _keyName, value: userId.toString());
  }
}
