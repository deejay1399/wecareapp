import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String _functionUrl =
      'https://ummiucjxysjuhirtrekw.supabase.co/functions/v1/create_payment_links';

  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtbWl1Y2p4eXNqdWhpcnRyZWt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1NjQ0NzYsImV4cCI6MjA3MjE0MDQ3Nn0.rcrhQ7by-AQk-SYtfEZYeUsUbMTj-aQHWj_2xGC_LfE';

  static Future<String?> createPaymentLink({
    required double amount,
    required String userId,
    required String planName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
        body: jsonEncode({
          'amount': amount,
          'user_id': userId,
          'plan_name': planName,
        }),
      );

      print('🔵 Response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['checkout_url'] != null) {
        final paymentLink = data['checkout_url'];
        print('✅ Payment Link: $paymentLink');
        return paymentLink;
      } else {
        print(
          '❌ Error: ${response.statusCode} - ${data['error'] ?? response.body}',
        );
        return null;
      }
    } catch (e) {
      print('💥 Exception: $e');
      return null;
    }
  }
}
