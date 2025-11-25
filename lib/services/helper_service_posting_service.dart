import '../models/helper_service_posting.dart';
import '../services/supabase_service.dart';
import '../services/subscription_service.dart';

class HelperServicePostingService {
  static const String _tableName = 'helper_service_postings';

  /// Create a new helper service posting
  static Future<HelperServicePosting> createServicePosting({
    required String helperId,
    required String title,
    required String description,
    required List<String> skills,
    required String experienceLevel,
    required double hourlyRate,
    required String availability,
    required List<String> serviceAreas,
  }) async {
    try {
      // Check if helper has active subscription
      final subscription = await SubscriptionService.getUserSubscription(
        helperId,
      );
      final hasValidSubscription = subscription?.isValidSubscription ?? false;

      // Only deduct trial limit if not subscribed
      if (!hasValidSubscription) {
        final deducted = await SubscriptionService.deductTrialLimit(
          helperId,
          'Helper',
          'helpers',
        );

        if (!deducted) {
          throw Exception(
            'Insufficient trial uses. Please subscribe to post services.',
          );
        }
      }

      final servicePosting = {
        'helper_id': helperId,
        'title': title,
        'description': description,
        'skills': skills,
        'experience_level': experienceLevel,
        'hourly_rate': hourlyRate,
        'availability': availability,
        'service_areas': serviceAreas,
        'status': 'active',
        'views_count': 0,
        'contacts_count': 0,
      };

      final response = await SupabaseService.client
          .from(_tableName)
          .insert(servicePosting)
          .select('*, helpers(first_name, last_name)')
          .single();

      return _mapToHelperServicePosting(response);
    } catch (e) {
      throw Exception('Failed to create service posting: $e');
    }
  }

  /// Get all service postings for a specific helper
  static Future<List<HelperServicePosting>> getServicePostingsByHelper(
    String helperId,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('*, helpers(first_name, last_name)')
          .eq('helper_id', helperId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => _mapToHelperServicePosting(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch service postings: $e');
    }
  }

  /// Get all active service postings
  static Future<List<HelperServicePosting>> getActiveServicePostings() async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('*, helpers(first_name, last_name)')
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => _mapToHelperServicePosting(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active service postings: $e');
    }
  }

  /// Get service postings by skill
  static Future<List<HelperServicePosting>> getServicePostingsBySkill(
    String skill,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('*, helpers(first_name, last_name)')
          .contains('skills', [skill])
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => _mapToHelperServicePosting(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch service postings by skill: $e');
    }
  }

  /// Get service postings by service area
  static Future<List<HelperServicePosting>> getServicePostingsByArea(
    String area,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('*, helpers(first_name, last_name)')
          .contains('service_areas', [area])
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => _mapToHelperServicePosting(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch service postings by area: $e');
    }
  }

  /// Update service posting
  static Future<HelperServicePosting> updateServicePosting({
    required String id,
    String? title,
    String? description,
    List<String>? skills,
    String? experienceLevel,
    double? hourlyRate,
    String? availability,
    List<String>? serviceAreas,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (skills != null) updateData['skills'] = skills;
      if (experienceLevel != null)
        updateData['experience_level'] = experienceLevel;
      if (hourlyRate != null) updateData['hourly_rate'] = hourlyRate;
      if (availability != null) updateData['availability'] = availability;
      if (serviceAreas != null) updateData['service_areas'] = serviceAreas;

      if (updateData.isEmpty) {
        throw Exception('No data to update');
      }

      final response = await SupabaseService.client
          .from(_tableName)
          .update(updateData)
          .eq('id', id)
          .select('*, helpers(first_name, last_name)')
          .single();

      return _mapToHelperServicePosting(response);
    } catch (e) {
      throw Exception('Failed to update service posting: $e');
    }
  }

  /// Update service posting status
  static Future<HelperServicePosting> updateServicePostingStatus(
    String id,
    String status,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .update({'status': status})
          .eq('id', id)
          .select('*, helpers(first_name, last_name)')
          .single();

      return _mapToHelperServicePosting(response);
    } catch (e) {
      throw Exception('Failed to update service posting status: $e');
    }
  }

  /// Increment views count
  static Future<bool> incrementViewsCount(
    String id,
    String viewerId,
    String viewerType,
  ) async {
    try {
      final response = await SupabaseService.client.rpc(
        'increment_service_views',
        params: {
          'service_id': id,
          'viewer_id': viewerId,
          'viewer_type': viewerType,
        },
      );

      // Return whether the view was actually recorded (not a duplicate)
      return response == true;
    } catch (e) {
      // Silently handle this error as it's not critical
      return false;
    }
  }

  /// Increment contacts count
  static Future<void> incrementContactsCount(String id) async {
    try {
      await SupabaseService.client.rpc(
        'increment_service_contacts',
        params: {'service_id': id},
      );
    } catch (e) {
      // Silently handle this error as it's not critical
    }
  }

  /// Delete service posting
  static Future<void> deleteServicePosting(String id) async {
    try {
      await SupabaseService.client.from(_tableName).delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete service posting: $e');
    }
  }

  /// Get service posting by ID
  static Future<HelperServicePosting> getServicePostingById(String id) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('*, helpers(first_name, last_name)')
          .eq('id', id)
          .single();

      return _mapToHelperServicePosting(response);
    } catch (e) {
      throw Exception('Failed to fetch service posting: $e');
    }
  }

  /// Private helper method to map database response to HelperServicePosting model
  static HelperServicePosting _mapToHelperServicePosting(
    Map<String, dynamic> data,
  ) {
    // Extract helper name from joined helpers table
    String helperName = 'Unknown Helper';
    if (data['helpers'] != null) {
      final helpers = data['helpers'] as Map<String, dynamic>;
      final firstName = helpers['first_name'] as String?;
      final lastName = helpers['last_name'] as String?;

      if (firstName != null && lastName != null) {
        helperName = '$firstName $lastName';
      } else if (firstName != null) {
        helperName = firstName;
      } else if (lastName != null) {
        helperName = lastName;
      }
    }

    return HelperServicePosting(
      id: data['id'] as String,
      helperId: data['helper_id'] as String,
      helperName: helperName,
      title: data['title'] as String,
      description: data['description'] as String,
      skills: List<String>.from(data['skills'] as List),
      experienceLevel: data['experience_level'] as String,
      hourlyRate: (data['hourly_rate'] as num).toDouble(),
      availability: data['availability'] as String,
      serviceAreas: List<String>.from(data['service_areas'] as List),
      createdDate: DateTime.parse(data['created_at'] as String),
      status: data['status'] as String,
      viewsCount: data['views_count'] as int? ?? 0,
      contactsCount: data['contacts_count'] as int? ?? 0,
    );
  }
}
