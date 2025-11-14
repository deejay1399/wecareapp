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

      // If a profile picture base64 string was provided, attempt to upload it to storage.
      // If upload succeeds we will store the public URL and NOT keep the base64 in DB.
      // If upload fails we will keep the base64 in the DB so the image can be recovered later.
      String? profilePictureValue; // public URL (if uploaded)
      final String? originalProfilePictureBase64 = profilePictureBase64;
      bool uploadSucceeded = false;
      String? uploadError;

      // Try to sign up the user in Supabase Auth first so uploads during registration
      // are performed with an authenticated session. If signUp fails we continue
      // but uploads may be rejected by storage RLS.
      try {
        final signUpRes = await SupabaseService.client.auth.signUp(
          email: email,
          password: password,
        );
      } catch (e) {
        // signUp failed - continue without printing debug
      }
      if (originalProfilePictureBase64 != null &&
          originalProfilePictureBase64.isNotEmpty) {
        try {
          // Convert base64 to bytes and guess extension
          String clean = originalProfilePictureBase64;
          if (clean.contains(',')) clean = clean.split(',').last;
          final bytes = base64Decode(clean);

          final ext = 'png';
          final filename =
              'profiles/helper_${DateTime.now().millisecondsSinceEpoch}.$ext';

          final publicUrl = await SupabaseService.uploadBytesToStorage(
            bucket: 'profile-picture',
            path: filename,
            bytes: Uint8List.fromList(bytes),
          );

          // Store public URL in profile_picture_url column and mark success
          profilePictureValue = publicUrl;
          uploadSucceeded = true;
        } catch (e) {
          uploadSucceeded = false;
          uploadError = e.toString();
        }
      }

      // Debug: print profile picture upload state before insert

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
            'skill': skills.join(', '),
            'experience': experience,
            'barangay': barangay,
            'barangay_clearance_base64': barangayClearanceBase64,
            // If upload succeeded we store the public URL and clear the base64 to avoid large rows.
            // If upload failed we keep the base64 so admin or a background job can retry.
            // NOTE: do NOT insert large base64 payloads when upload failed.
            // Storing the base64 on failure previously caused Postgres index
            // size errors in some environments. We keep the base64 only in
            // the client memory for retry after login.
            'profile_picture_base64': uploadSucceeded ? null : null,
            'profile_picture_url': uploadSucceeded ? profilePictureValue : null,
          })
          .select()
          .single();

      final helper = Helper.fromMap(response);

      return {
        'success': true,
        'message': uploadSucceeded
            ? 'Registration successful'
            : 'Registration successful (profile picture upload failed)',
        'helper': helper,
        'uploadSucceeded': uploadSucceeded,
        'uploadError': uploadError,
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

      // After login, if there is a preserved base64 image but no public URL, try to upload it now.
      try {
        final hasBase64 = response['profile_picture_base64'] != null;
        final hasUrl = response['profile_picture_url'] != null;
        if (hasBase64 && !hasUrl) {
          final base64 = response['profile_picture_base64'] as String;

          await HelperAuthService.updateProfilePicture(
            id: helper.id,
            profilePictureBase64: base64,
          );
        }
      } catch (e) {
        debugPrint('DEBUG: loginHelper post-login upload retry failed: $e');
      }

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
      if (barangayClearanceBase64 != null) {
        updateData['barangay_clearance_base64'] = barangayClearanceBase64;
      }
      if (profilePictureBase64 != null) {
        // If profilePictureBase64 looks like a large base64 payload, upload to storage
        String? profilePictureValue = profilePictureBase64;
        try {
          String clean = profilePictureBase64;
          if (clean.contains(',')) clean = clean.split(',').last;
          final bytes = base64Decode(clean);

          // Only try upload if size exceeds small threshold or if it's indeed base64
          if (bytes.length > 2000) {
            final filename =
                'profiles/helper_${id}_${DateTime.now().millisecondsSinceEpoch}.png';

            final publicUrl = await SupabaseService.uploadBytesToStorage(
              bucket: 'profile-picture',
              path: filename,
              bytes: Uint8List.fromList(bytes),
            );

            profilePictureValue = publicUrl;
          }
        } catch (e) {
          // ignore and fallback to provided value
        }

        // store URL in profile_picture_url and clear base64 to avoid large DB rows
        updateData['profile_picture_base64'] = null;
        updateData['profile_picture_url'] = profilePictureValue;
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

  // Update profile picture only
  static Future<Map<String, dynamic>> updateProfilePicture({
    required String id,
    String? profilePictureBase64,
  }) async {
    try {
      String? profilePictureValue = profilePictureBase64;
      if (profilePictureBase64 != null) {
        try {
          String clean = profilePictureBase64;
          if (clean.contains(',')) clean = clean.split(',').last;
          final bytes = base64Decode(clean);
          final filename =
              'profiles/helper_${id}_${DateTime.now().millisecondsSinceEpoch}.png';

          final publicUrl = await SupabaseService.uploadBytesToStorage(
            bucket: 'profile-picture',
            path: filename,
            bytes: Uint8List.fromList(bytes),
          );

          profilePictureValue = publicUrl;
        } catch (e) {
          // if upload fails, allow clearing the picture or storing null
        }
      }

      final response = await SupabaseService.client
          .from(_tableName)
          .update({
            'profile_picture_base64': null,
            'profile_picture_url': profilePictureValue,
          })
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
