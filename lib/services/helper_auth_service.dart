import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
    required List<String> skills,
    required String experience,
    required String municipality,
    required String barangay,
    String? policeClearanceBase64,
    String? policeClearanceExpiryDate,
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

      final passwordHash = _createPasswordHash(password);

      // Upload profile picture to storage (URL only)
      String? profilePictureUrl;
      bool uploadSucceeded = false;
      String? uploadError;

      try {
        await SupabaseService.client.auth.signUp(
          email: email,
          password: password,
        );
      } catch (e) {
        // Ignore Supabase auth signup errors for now
      }

      if (profilePictureBase64 != null && profilePictureBase64.isNotEmpty) {
        try {
          String clean = profilePictureBase64;
          if (clean.contains(',')) clean = clean.split(',').last;
          final bytes = base64Decode(clean);

          final filename =
              'profiles/helper_${DateTime.now().millisecondsSinceEpoch}.png';

          profilePictureUrl = await SupabaseService.uploadBytesToStorage(
            bucket: 'profile-picture',
            path: filename,
            bytes: Uint8List.fromList(bytes),
          );

          uploadSucceeded = true;
        } catch (e) {
          uploadSucceeded = false;
          uploadError = e.toString();
        }
      }

      // Insert new helper (URL only, no base64 saved)
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
            'skill': skills.join(', '),
            'experience': experience,
            'municipality': municipality,
            'barangay': barangay,
            'police_clearance_base64': policeClearanceBase64,
            'police_clearance_expiry_date': policeClearanceExpiryDate,
            'profile_picture_url': uploadSucceeded ? profilePictureUrl : null,
            'is_allowed': true,
            'is_verified': true,
            'trial_limit': 8,
            'completed_jobs_count': 0,
          })
          .select()
          .single();

      final helper = Helper.fromMap(response);

      return {
        'success': true,
        'message': uploadSucceeded
            ? 'Registration successful'
            : 'Registration successful',
        'helper': helper,
        'uploadSucceeded': uploadSucceeded,
        'uploadError': uploadError,
      };
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginHelper({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      bool isEmail = emailOrPhone.contains('@');
      String column = isEmail ? 'email' : 'phone';

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

      final storedPasswordHash = response['password_hash'] as String;
      if (!_verifyPassword(password, storedPasswordHash)) {
        return {'success': false, 'message': 'Invalid password'};
      }

      // Check if helper is allowed (not blocked)
      final isAllowed = response['is_allowed'] as bool?;
      if (isAllowed == false) {
        return {
          'success': false,
          'message': 'Your account has been blocked. Please contact support.',
          'isBlocked': true,
        };
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
    String? policeClearanceBase64,
    String? policeClearanceExpiryDate,
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
      if (policeClearanceBase64 != null) {
        updateData['police_clearance_base64'] = policeClearanceBase64;
      }
      if (policeClearanceExpiryDate != null) {
        updateData['police_clearance_expiry_date'] = policeClearanceExpiryDate;
      }

      // Profile picture update (URL only)
      if (profilePictureBase64 != null) {
        try {
          String clean = profilePictureBase64;
          if (clean.contains(',')) clean = clean.split(',').last;
          final bytes = base64Decode(clean);

          final filename =
              'profiles/helper_${id}_${DateTime.now().millisecondsSinceEpoch}.png';

          final url = await SupabaseService.uploadBytesToStorage(
            bucket: 'profile-picture',
            path: filename,
            bytes: Uint8List.fromList(bytes),
          );

          updateData['profile_picture_url'] = url;
        } catch (e) {
          // ignore upload failure; don't update URL
        }
      }

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

  // Update profile picture only (URL only)
  static Future<Map<String, dynamic>> updateProfilePicture({
    required String id,
    String? profilePictureBase64,
  }) async {
    try {
      String? pictureUrl;

      if (profilePictureBase64 != null) {
        try {
          String clean = profilePictureBase64;
          if (clean.contains(',')) clean = clean.split(',').last;
          final bytes = base64Decode(clean);

          final filename =
              'profiles/helper_${id}_${DateTime.now().millisecondsSinceEpoch}.png';

          pictureUrl = await SupabaseService.uploadBytesToStorage(
            bucket: 'profile-picture',
            path: filename,
            bytes: Uint8List.fromList(bytes),
          );
        } catch (e) {
          // failed upload, url stays null
        }
      }

      final response = await SupabaseService.client
          .from(_tableName)
          .update({'profile_picture_url': pictureUrl})
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
