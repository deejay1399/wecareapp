import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../models/employer.dart';
import '../services/supabase_service.dart';

class EmployerAuthService {
  static const String _tableName = 'employers';

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

  // Register new employer
  static Future<Map<String, dynamic>> registerEmployer({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String birthdate,
    required int age,
    required String password,
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

      // Hash password
      final passwordHash = _createPasswordHash(password);

      // If a profile picture base64 string was provided, attempt upload.
      // On success we store public URL and clear base64; on failure we keep the base64 so it can be retried later.
      String? profilePictureValue;
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
        debugPrint(
          'DEBUG: employer.registerEmployer auth.signUp result: ${signUpRes.user != null}',
        );
        // Ensure we have an authenticated session; if not, try signInWithPassword
        if (SupabaseService.client.auth.currentUser == null) {
          try {
            final signInRes = await SupabaseService.client.auth
                .signInWithPassword(email: email, password: password);
            debugPrint(
              'DEBUG: employer.registerEmployer auth.signIn result: ${signInRes.user != null}',
            );
          } catch (e) {
            debugPrint(
              'DEBUG: employer.registerEmployer auth.signIn failed: $e',
            );
          }
        }
      } catch (e) {
        debugPrint('DEBUG: employer.registerEmployer auth.signUp failed: $e');
      }

      if (originalProfilePictureBase64 != null &&
          originalProfilePictureBase64.isNotEmpty) {
        try {
          String clean = originalProfilePictureBase64;
          if (clean.contains(',')) clean = clean.split(',').last;
          final bytes = base64Decode(clean);
          final filename =
              'profiles/employer_${DateTime.now().millisecondsSinceEpoch}.png';

          debugPrint(
            'DEBUG: employer.registerEmployer uploading profile picture bytes=${bytes.length}',
          );
          final publicUrl = await SupabaseService.uploadBytesToStorage(
            bucket: 'profile-picture',
            path: filename,
            bytes: Uint8List.fromList(bytes),
          );
          debugPrint(
            'DEBUG: employer.registerEmployer upload returned publicUrl=$publicUrl',
          );

          profilePictureValue = publicUrl;
          uploadSucceeded = true;
        } catch (e) {
          debugPrint('DEBUG: employer.registerEmployer upload failed: $e');
          // Avoid writing the large base64 blob into the DB when upload fails
          // because that can trigger Postgres index size errors on some setups.
          uploadSucceeded = false;
          uploadError = e.toString();
        }
      }

      // Debug: print profile picture upload state before insert
      debugPrint(
        'DEBUG: employer.registerEmployer uploadSucceeded=$uploadSucceeded, profilePictureValue=${profilePictureValue != null ? profilePictureValue.length : 0}, base64Length=${originalProfilePictureBase64 != null ? originalProfilePictureBase64.length : 0}',
      );

      // Insert new employer
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
            'municipality': municipality,
            'barangay': barangay,
            'police_clearance_base64': policeClearanceBase64,
            'police_clearance_expiry_date': policeClearanceExpiryDate,
            // NOTE: avoid inserting large base64 payloads on failure to prevent
            // DB index size issues. The client should retry upload after login.
            'profile_picture_base64': uploadSucceeded ? null : null,
            'profile_picture_url': uploadSucceeded ? profilePictureValue : null,
            'is_allowed': true,
            'is_verified': true,
            'trial_limit': 5,
            'completed_jobs_count': 0,
          })
          .select()
          .single();

      final employer = Employer.fromMap(response);

      return {
        'success': true,
        'message': uploadSucceeded
            ? 'Registration successful'
            : 'Registration successful (profile picture upload failed)',
        'employer': employer,
        'uploadSucceeded': uploadSucceeded,
        'uploadError': uploadError,
      };
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  // Login employer
  static Future<Map<String, dynamic>> loginEmployer({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      // Determine if input is email or phone
      bool isEmail = emailOrPhone.contains('@');
      String column = isEmail ? 'email' : 'phone';

      // Find employer by email or phone
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

      // Check if employer is allowed (not blocked)
      final isAllowed = response['is_allowed'] as bool?;
      if (isAllowed == false) {
        return {
          'success': false,
          'message': 'Your account has been blocked. Please contact support.',
          'isBlocked': true,
        };
      }

      final employer = Employer.fromMap(response);

      // After login, if there is a preserved base64 image but no public URL, try to upload it now.
      try {
        final hasBase64 = response['profile_picture_base64'] != null;
        final hasUrl = response['profile_picture_url'] != null;
        if (hasBase64 && !hasUrl) {
          final base64 = response['profile_picture_base64'] as String;
          debugPrint(
            'DEBUG: loginEmployer found preserved base64, attempting upload...',
          );
          await EmployerAuthService.updateProfilePicture(
            id: employer.id,
            profilePictureBase64: base64,
          );
        }
      } catch (e) {
        debugPrint('DEBUG: loginEmployer post-login upload retry failed: $e');
      }

      return {
        'success': true,
        'message': 'Login successful',
        'employer': employer,
      };
    } catch (e) {
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  // Get employer by ID
  static Future<Employer?> getEmployerById(String id) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return Employer.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  // Update employer profile
  static Future<Map<String, dynamic>> updateEmployerProfile({
    required String id,
    String? firstName,
    String? lastName,
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
      if (municipality != null) updateData['municipality'] = municipality;
      if (barangay != null) updateData['barangay'] = barangay;
      if (policeClearanceBase64 != null) {
        updateData['police_clearance_base64'] = policeClearanceBase64;
      }
      if (policeClearanceExpiryDate != null) {
        updateData['police_clearance_expiry_date'] = policeClearanceExpiryDate;
      }
      if (profilePictureBase64 != null) {
        String? profilePictureValue;
        final String originalProfilePictureBase64 = profilePictureBase64;
        bool uploadSucceeded = false;
        try {
          String clean = profilePictureBase64;
          if (clean.contains(',')) clean = clean.split(',').last;
          final bytes = base64Decode(clean);
          if (bytes.length > 2000) {
            final filename =
                'profiles/employer_${id}_${DateTime.now().millisecondsSinceEpoch}.png';
            debugPrint(
              'DEBUG: employer.updateEmployerProfile uploading profile picture bytes=${bytes.length}',
            );
            final publicUrl = await SupabaseService.uploadBytesToStorage(
              bucket: 'profile-picture',
              path: filename,
              bytes: Uint8List.fromList(bytes),
            );
            debugPrint(
              'DEBUG: employer.updateEmployerProfile upload returned publicUrl=$publicUrl',
            );
            profilePictureValue = publicUrl;
            uploadSucceeded = true;
          }
        } catch (e) {
          debugPrint('DEBUG: employer.updateEmployerProfile upload failed: $e');
          uploadSucceeded = false;
        }

        // store URL in profile_picture_url and clear base64 only if upload succeeded
        updateData['profile_picture_base64'] = uploadSucceeded
            ? null
            : originalProfilePictureBase64;
        updateData['profile_picture_url'] = uploadSucceeded
            ? profilePictureValue
            : null;
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

      final employer = Employer.fromMap(response);

      return {
        'success': true,
        'message': 'Profile updated successfully',
        'employer': employer,
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
      final String? originalProfilePictureBase64 = profilePictureBase64;
      String? profilePictureValue;
      bool uploadSucceeded = false;
      if (originalProfilePictureBase64 != null) {
        try {
          String clean = originalProfilePictureBase64;
          if (clean.contains(',')) clean = clean.split(',').last;
          final bytes = base64Decode(clean);
          final filename =
              'profiles/employer_${id}_${DateTime.now().millisecondsSinceEpoch}.png';
          debugPrint(
            'DEBUG: employer.updateProfilePicture uploading profile picture bytes=${bytes.length}',
          );
          final publicUrl = await SupabaseService.uploadBytesToStorage(
            bucket: 'profile-picture',
            path: filename,
            bytes: Uint8List.fromList(bytes),
          );
          debugPrint(
            'DEBUG: employer.updateProfilePicture upload returned publicUrl=$publicUrl',
          );
          profilePictureValue = publicUrl;
          uploadSucceeded = true;
        } catch (e) {
          debugPrint('DEBUG: employer.updateProfilePicture upload failed: $e');
          uploadSucceeded = false;
        }
      }

      final response = await SupabaseService.client
          .from(_tableName)
          .update({
            'profile_picture_base64': uploadSucceeded
                ? null
                : originalProfilePictureBase64,
            'profile_picture_url': uploadSucceeded ? profilePictureValue : null,
          })
          .eq('id', id)
          .select()
          .single();

      final employer = Employer.fromMap(response);

      return {
        'success': true,
        'message': profilePictureBase64 != null
            ? 'Profile picture updated successfully'
            : 'Profile picture removed successfully',
        'employer': employer,
      };
    } catch (e) {
      return {'success': false, 'message': 'Profile picture update failed: $e'};
    }
  }
}
