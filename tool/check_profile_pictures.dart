import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:wecareapp/services/supabase_service.dart';

Future<void> main() async {
  print('Initializing Supabase...');
  await SupabaseService.initialize();

  print('Fetching helpers...');
  final response = await SupabaseService.client
      .from('helpers')
      .select('id, profile_picture_url');

  final rows = (response as List<dynamic>);

  if (rows.isEmpty) {
    print('No helpers found or no profile_picture_url values.');
    return;
  }

  int total = 0;
  int missing = 0;

  for (final row in rows) {
    final id = row['id'];
    final url = row['profile_picture_url'] as String?;
    if (url == null || url.trim().isEmpty) continue;

    total++;
    try {
      final uri = Uri.parse(url);
      final head = await http.head(uri).timeout(const Duration(seconds: 5));
      if (head.statusCode == 200) {
        print('OK   - id=$id url=$url');
      } else {
        missing++;
        print('MISS - id=$id url=$url status=${head.statusCode}');
      }
    } on TimeoutException catch (_) {
      missing++;
      print('MISS - id=$id url=$url status=TIMEOUT');
    } catch (e) {
      missing++;
      print('ERR  - id=$id url=$url error=$e');
    }
  }

  print('Checked $total URLs, $missing missing/unreachable');
}
