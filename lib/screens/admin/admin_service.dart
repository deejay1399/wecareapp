import 'package:wecareapp/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  /// Example: Authenticate admin user
  static Future<AuthResponse> signInAdmin({
    required String email,
    required String password,
  }) async {
    // Ensure Supabase is initialized before calling
    if (!SupabaseService.isInitialized) {
      await SupabaseService.initialize();
    }
    return await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Example: Fetch all users (admins only, if you have a role column)
  static Future<List<Map<String, dynamic>>> getAdminUsers() async {
    final response = await SupabaseService.client
        .from('users')
        .select()
        .eq('role', 'admin');
    return (response as List).cast<Map<String, dynamic>>();
  }

  // Add more admin-specific methods as needed
  /// Fetch all subscriptions with diagnostics
  static Future<List<Map<String, dynamic>>> getSubscriptions() async {
    // Diagnostic: Check Supabase initialization
    if (!SupabaseService.isInitialized) {
      debugPrint(
        '[AdminService] Supabase not initialized. Initializing now...',
      );
      await SupabaseService.initialize();
      debugPrint('[AdminService] Supabase initialized.');
    }
    try {
      debugPrint('[AdminService] Querying table: subscriptions');
      final response = await SupabaseService.client
          .from('subscriptions')
          .select();
      debugPrint('[AdminService] Query result: ${response.runtimeType}');
      debugPrint('[AdminService] Subscription count: ${response.length}');
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[AdminService] Error querying subscriptions: $e');
      rethrow;
    }
  }
}
