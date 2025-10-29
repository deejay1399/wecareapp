import '../models/helper.dart';
import 'supabase_service.dart';

class HelperService {
  final _client = SupabaseService.client;

  Future<Helper?> getHelperById(String helperId) async {
    if (helperId.isEmpty) return null;

    try {
      final response = await _client
          .from('helpers')
          .select()
          .eq('id', helperId)
          .maybeSingle();

      if (response == null) return null;
      return Helper.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch helper: $e');
    }
  }
}
