import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../utils/constants/supabase_config.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  static bool get isInitialized => _client != null;

  /// Upload raw bytes to a storage bucket and return the public URL on success.
  /// path should include any folders and filename, e.g. 'profiles/12345.png'
  static Future<String> uploadBytesToStorage({
    required String bucket,
    required String path,
    required Uint8List bytes,
  }) async {
    if (_client == null) throw Exception('Supabase not initialized');

    // Ensure bucket exists on Supabase side. The SDK will error if not.
    final storage = _client!.storage.from(bucket);

    try {
      // Attempt binary upload (SDK provides uploadBinary)
      debugPrint(
        'DEBUG: Uploading to storage bucket="$bucket" path="$path" bytes=${bytes.length}',
      );
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      // Get public URL
      final dynamic publicUrlResponse = storage.getPublicUrl(path);
      debugPrint('DEBUG: storage.getPublicUrl response: $publicUrlResponse');

      // If SDK returns a simple string URL
      if (publicUrlResponse is String && publicUrlResponse.isNotEmpty) {
        // Verify public URL is reachable before returning
        final publicUrl = publicUrlResponse;
        try {
          final headResp = await http.head(Uri.parse(publicUrl));
          if (headResp.statusCode == 200) return publicUrl;
          debugPrint(
            'DEBUG: public URL HEAD returned status=${headResp.statusCode} for $publicUrl',
          );
        } catch (e) {
          debugPrint('DEBUG: failed to verify public URL $publicUrl: $e');
        }

        throw Exception('Public URL unreachable: $publicUrl');
      }

      // If SDK returns a map-like response with a public URL field
      if (publicUrlResponse is Map) {
        String? candidate;
        if (publicUrlResponse['publicUrl'] is String) {
          candidate = publicUrlResponse['publicUrl'] as String;
        }
        if (publicUrlResponse['publicURL'] is String) {
          candidate = publicUrlResponse['publicURL'] as String;
        }
        if (publicUrlResponse['public_url'] is String) {
          candidate = publicUrlResponse['public_url'] as String;
        }

        if (candidate != null && candidate.isNotEmpty) {
          try {
            final headResp = await http.head(Uri.parse(candidate));
            if (headResp.statusCode == 200) return candidate;
            debugPrint(
              'DEBUG: public URL HEAD returned status=${headResp.statusCode} for $candidate',
            );
          } catch (e) {
            debugPrint('DEBUG: failed to verify public URL $candidate: $e');
          }

          throw Exception('Public URL unreachable: $candidate');
        }
      }

      throw Exception(
        'Unexpected response from getPublicUrl: $publicUrlResponse',
      );
    } catch (e) {
      debugPrint('DEBUG: Storage upload failed: $e');
      throw Exception('Storage upload failed: $e');
    }
  }
}
