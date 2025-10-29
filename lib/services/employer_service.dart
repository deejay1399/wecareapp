import '../models/employer.dart';
import 'supabase_service.dart';

class EmployerService {
  final _client = SupabaseService.client;

  Future<Employer?> getEmployerById(String employerId) async {
    if (employerId.isEmpty) return null;

    try {
      final response = await _client
          .from('employers')
          .select()
          .eq('id', employerId)
          .maybeSingle();

      if (response == null) return null;
      return Employer.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch employer: $e');
    }
  }
}
