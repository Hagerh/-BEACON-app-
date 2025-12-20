import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Service to manage permanent user ID
/// This ID persists across app restarts and network sessions
class UserIdService {
  static const String _userIdKey = 'permanent_user_id';
  static final _uuid = Uuid();

  /// Get or generate a permanent user ID
  /// This is called once when the app first runs, and stored permanently
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we already have a user ID
    String? userId = prefs.getString(_userIdKey);

    if (userId == null || userId.isEmpty) {
      // Generate a new permanent user ID
      userId = _uuid.v4();
      await prefs.setString(_userIdKey, userId);
    }

    return userId;
  }

  /// Reset user ID (for testing or account deletion)
  static Future<void> resetUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  /// Check if user ID exists
  static Future<bool> hasUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userIdKey);
  }
}
