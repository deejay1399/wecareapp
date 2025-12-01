import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/employer.dart';
import '../models/helper.dart';

class SessionService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserType = 'user_type';
  static const String _keyUserId = 'user_id';
  static const String _keyUserData = 'user_data';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyEmailOrPhone = 'email_or_phone';

  // Save login session
  static Future<void> saveLoginSession({
    required String userType,
    required String userId,
    required Map<String, dynamic> userData,
    bool rememberMe = false,
    String? emailOrPhone,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserType, userType);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserData, jsonEncode(userData));
    await prefs.setBool(_keyRememberMe, rememberMe);

    if (rememberMe && emailOrPhone != null) {
      await prefs.setString(_keyEmailOrPhone, emailOrPhone);
    }
  }

  // Validate session integrity
  static Future<bool> validateSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      if (!isLoggedIn) return false;

      final userType = prefs.getString(_keyUserType);
      final userId = prefs.getString(_keyUserId);
      final userDataJson = prefs.getString(_keyUserData);

      // Check if all required data exists
      if (userType == null || userId == null || userDataJson == null) {
        await clearSession();
        return false;
      }

      // Validate user type
      if (userType != 'Employer' && userType != 'Helper') {
        await clearSession();
        return false;
      }

      // Try to parse user data
      try {
        final userData = jsonDecode(userDataJson) as Map<String, dynamic>;

        // Validate that userData has required fields
        if (!userData.containsKey('id') || !userData.containsKey('email')) {
          await clearSession();
          return false;
        }

        return true;
      } catch (e) {
        await clearSession();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Clear invalid session data
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserType);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserData);
    // Keep remember me data if it exists
  }

  // Get current user type
  static Future<String?> getCurrentUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserType);
  }

  // Get current user ID
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  // Get current employer data
  static Future<Employer?> getCurrentEmployer() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString(_keyUserType);

    if (userType != 'Employer') return null;

    final userDataJson = prefs.getString(_keyUserData);
    if (userDataJson == null) return null;

    try {
      final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
      return Employer.fromMap(userData);
    } catch (e) {
      return null;
    }
  }

  // Get current helper data
  static Future<Helper?> getCurrentHelper() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString(_keyUserType);

    if (userType != 'Helper') return null;

    final userDataJson = prefs.getString(_keyUserData);
    if (userDataJson == null) return null;

    try {
      final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
      return Helper.fromMap(userData);
    } catch (e) {
      return null;
    }
  }

  // Update current user data
  static Future<void> updateCurrentUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, jsonEncode(userData));
  }

  // Check if user is logged in with validation
  static Future<bool> isLoggedIn() async {
    final basicCheck = await _isBasicLoggedIn();
    if (!basicCheck) return false;

    // Validate session integrity
    return await validateSession();
  }

  // Basic login check without validation
  static Future<bool> _isBasicLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Check if remember me is enabled
  static Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  // Get remembered email or phone
  static Future<String?> getRememberedEmailOrPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;

    if (!rememberMe) return null;

    return prefs.getString(_keyEmailOrPhone);
  }

  // Logout and clear session
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Get user ID before clearing to clean up subscription data
    final userId = prefs.getString(_keyUserId);

    // CRITICAL: Clear subscription cache before clearing all session data
    // This ensures that stale subscription data won't show after re-login
    if (userId != null) {
      await _clearAllSubscriptionCacheForUser(userId);
    }

    // Clear all session data
    await prefs.clear();

    // Specifically clear the requested keys if they exist
    await prefs.remove('flutter.remember.me');
    await prefs.remove('flutter.email_or_phone');

    print('✅ Logout complete - subscription cache cleared');
  }

  // Clear ALL subscription-related cache keys for a user
  static Future<void> _clearAllSubscriptionCacheForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Clear subscription keys
    final keys = await prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith('subscription_$userId') ||
          key.startsWith('usage_tracking_$userId')) {
        await prefs.remove(key);
      }
    }

    print('🧹 Cleared all subscription cache for user $userId');
  }

  // Clear all data including remember me
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
