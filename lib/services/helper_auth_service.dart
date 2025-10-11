import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/helper.dart';
import '../services/supabase_service.dart';

class HelperAuthService {
  static const String _tableName = 'helpers';

  // Hash password using SHA-256 with salt
  static String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate random salt
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  // Combine password hash with salt for storage
  static String _createPasswordHash(String password) {
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    return '$salt:$hash';
  }

  // Verify password against stored hash
  static bool _verifyPassword(String password, String storedHash) {
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;

    final salt = parts[0];
    final hash = parts[1];
    final computedHash = _hashPassword(password, salt);

    return hash == computedHash;
  }

  // Register new helper
  static Future<Map<String, dynamic>> registerHelper({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String birthdate,
    required int age,
    required String password,
    required String skill,
    required String experience,
    required String municipality,
    required String barangay,
    String? barangayClearanceBase64,
    String? profilePictureBase64,
  }) async {
    try {
      // Check if email already exists
      final emailCheck = await SupabaseService.client
          .from(_tableName)
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (emailCheck != null) {
        return {
          'success': false,
          'message': 'An account with this email already exists',
        };
      }

      // Check if phone already exists
      final phoneCheck = await SupabaseService.client
          .from(_tableName)
          .select('id')
          .eq('phone', phone)
          .maybeSingle();

      if (phoneCheck != null) {
        return {
          'success': false,
          'message': 'An account with this phone number already exists',
        };
      }

      // Hash password
      final passwordHash = _createPasswordHash(password);

      // Insert new helper
      final response = await SupabaseService.client
          .from(_tableName)
          .insert({
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'phone': phone,
            'birthdate': birthdate,
            'age': age,
            'password_hash': passwordHash,
            'skill': skill,
            'experience': experience,
            'barangay': barangay,
            'barangay_clearance_base64': barangayClearanceBase64,
            'profile_picture_base64': profilePictureBase64,
          })
          .select()
          .single();

      final helper = Helper.fromMap(response);

      return {
        'success': true,
        'message': 'Registration successful',
        'helper': helper,
      };
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  // Login helper
  static Future<Map<String, dynamic>> loginHelper({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      // Determine if input is email or phone
      bool isEmail = emailOrPhone.contains('@');
      String column = isEmail ? 'email' : 'phone';

      // Find helper by email or phone
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq(column, emailOrPhone)
          .maybeSingle();

      if (response == null) {
        return {
          'success': false,
          'message':
              'No account found with this ${isEmail ? 'email' : 'phone number'}',
        };
      }

      // Verify password
      final storedPasswordHash = response['password_hash'] as String;
      if (!_verifyPassword(password, storedPasswordHash)) {
        return {'success': false, 'message': 'Invalid password'};
      }

      final helper = Helper.fromMap(response);

      return {'success': true, 'message': 'Login successful', 'helper': helper};
    } catch (e) {
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  // Get helper by ID
  static Future<Helper?> getHelperById(String id) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return Helper.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  // Update helper profile
  static Future<Map<String, dynamic>> updateHelperProfile({
    required String id,
    String? firstName,
    String? lastName,
    String? skill,
    String? experience,
    String? municipality,
    String? barangay,
    String? barangayClearanceBase64,
    String? profilePictureBase64,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;
      if (skill != null) updateData['skill'] = skill;
      if (experience != null) updateData['experience'] = experience;
      if (municipality != null) updateData['municipality'] = municipality;
      if (barangay != null) updateData['barangay'] = barangay;
      if (barangayClearanceBase64 != null)
        updateData['barangay_clearance_base64'] = barangayClearanceBase64;
      if (profilePictureBase64 != null)
        updateData['profile_picture_base64'] = profilePictureBase64;

      if (updateData.isEmpty) {
        return {'success': false, 'message': 'No data to update'};
      }

      final response = await SupabaseService.client
          .from(_tableName)
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      final helper = Helper.fromMap(response);

      return {
        'success': true,
        'message': 'Profile updated successfully',
        'helper': helper,
      };
    } catch (e) {
      return {'success': false, 'message': 'Update failed: $e'};
    }
  }

  // Update profile picture only
  static Future<Map<String, dynamic>> updateProfilePicture({
    required String id,
    String? profilePictureBase64,
  }) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .update({'profile_picture_base64': profilePictureBase64})
          .eq('id', id)
          .select()
          .single();

      final helper = Helper.fromMap(response);

      return {
        'success': true,
        'message': profilePictureBase64 != null
            ? 'Profile picture updated successfully'
            : 'Profile picture removed successfully',
        'helper': helper,
      };
    } catch (e) {
      return {'success': false, 'message': 'Profile picture update failed: $e'};
    }
  }
}
