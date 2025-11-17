import '../models/application.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import 'job_posting_service.dart';

class ApplicationService {
  static const String _tableName = 'applications';

  /// Apply for a job
  static Future<Application> applyForJob({
    required String jobPostingId,
    required String helperId,
    required String helperName,
    required String coverLetter,
  }) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .insert({
            'job_posting_id': jobPostingId,
            'helper_id': helperId,
            'cover_letter': coverLetter,
            'status': 'pending',
          })
          .select()
          .single();

      // Get job details to notify employer
      try {
        final jobResponse = await SupabaseService.client
            .from('job_postings')
            .select('employer_id, title')
            .eq('id', jobPostingId)
            .single();

        final employerId = jobResponse['employer_id'] as String;
        final jobTitle = jobResponse['title'] as String;

        // Create notification for employer
        await NotificationService.createNotification(
          recipientId: employerId,
          title: 'New Application',
          body: '$helperName applied for "$jobTitle"',
          type: 'job_application',
          category: 'new',
          targetId: jobPostingId,
        );
      } catch (e) {
        print('Error creating application notification: $e');
      }

      return _mapToApplication(response);
    } catch (e) {
      throw Exception('Failed to apply for job: $e');
    }
  }

  /// Get applications for a specific job posting (for employers)
  static Future<List<Application>> getApplicationsForJob(
    String jobPostingId,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('''
            *,
            helpers (
              first_name,
              last_name,
              email,
              phone,
              skill,
              experience,
              barangay
            ),
            job_postings (
              title
            )
          ''')
          .eq('job_posting_id', jobPostingId)
          .order('applied_at', ascending: false);

      return (response as List)
          .map((data) => _mapToApplicationWithDetails(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch applications for job: $e');
    }
  }

  /// Get applications by helper (for helpers to see their applications)
  static Future<List<Application>> getApplicationsByHelper(
    String helperId,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('''
            *,
            job_postings (
              title,
              description,
              salary,
              payment_frequency,
              barangay,
              status
            )
          ''')
          .eq('helper_id', helperId)
          .order('applied_at', ascending: false);

      return (response as List)
          .map((data) => _mapToApplicationWithJobDetails(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch helper applications: $e');
    }
  }

  /// Update application status (for employers)
  static Future<Application> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    try {
      // First get the application details
      final appResponse = await SupabaseService.client
          .from(_tableName)
          .select('''
            *,
            helpers (
              first_name,
              last_name,
              email,
              phone,
              skill,
              experience,
              barangay
            ),
            job_postings (
              title
            )
          ''')
          .eq('id', applicationId)
          .single();

      final helperId = appResponse['helper_id'] as String;
      final helperData = appResponse['helpers'] as Map<String, dynamic>;
      final helperName =
          '${helperData['first_name']} ${helperData['last_name']}';
      final jobData = appResponse['job_postings'] as Map<String, dynamic>;
      final jobTitle = jobData['title'] as String;

      // Update the application status
      await SupabaseService.client
          .from(_tableName)
          .update({'status': status})
          .eq('id', applicationId);

      // Create notification for helper
      if (status == 'accepted') {
        await NotificationService.createNotification(
          recipientId: helperId,
          title: 'Application Accepted! 🎉',
          body: 'Your application for "$jobTitle" has been accepted',
          type: 'application_accepted',
          category: 'new',
          targetId: appResponse['job_posting_id'] as String,
        );

        final jobId = appResponse['job_posting_id'] as String;

        // Assign helper to job (this moves job to 'in_progress' status)
        await JobPostingService.assignHelperToJob(
          jobId: jobId,
          helperId: helperId,
          helperName: helperName,
        );

        // Reject all other pending applications for this job
        await SupabaseService.client
            .from(_tableName)
            .update({'status': 'rejected'})
            .eq('job_posting_id', jobId)
            .neq('id', applicationId)
            .eq('status', 'pending');

        // Create rejection notifications for other helpers
        final otherApps = await SupabaseService.client
            .from(_tableName)
            .select('helper_id')
            .eq('job_posting_id', jobId)
            .eq('status', 'rejected');

        for (var app in otherApps as List) {
          try {
            await NotificationService.createNotification(
              recipientId: app['helper_id'] as String,
              title: 'Application Not Selected',
              body: 'We chose another candidate for "$jobTitle"',
              type: 'application_rejected',
              category: 'previous',
              targetId: jobId,
            );
          } catch (e) {
            print('Error notifying rejected helper: $e');
          }
        }
      } else if (status == 'rejected') {
        // Direct rejection by employer
        await NotificationService.createNotification(
          recipientId: helperId,
          title: 'Application Not Selected',
          body:
              'Unfortunately, your application for "$jobTitle" was not selected',
          type: 'application_rejected',
          category: 'previous',
          targetId: appResponse['job_posting_id'] as String,
        );
      }

      // Return the updated application
      appResponse['status'] = status;
      return _mapToApplicationWithDetails(appResponse);
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }

  /// Withdraw application (for helpers)
  static Future<Application> withdrawApplication(String applicationId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .update({'status': 'withdrawn'})
          .eq('id', applicationId)
          .select('''
            *,
            job_postings (
              title,
              description,
              salary,
              payment_frequency,
              barangay,
              status
            )
          ''')
          .single();

      return _mapToApplicationWithJobDetails(response);
    } catch (e) {
      throw Exception('Failed to withdraw application: $e');
    }
  }

  /// Check if helper has already applied for a job
  static Future<bool> hasApplied(String jobPostingId, String helperId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('id')
          .eq('job_posting_id', jobPostingId)
          .eq('helper_id', helperId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check application status: $e');
    }
  }

  /// Get application by ID
  static Future<Application> getApplicationById(String applicationId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('''
            *,
            helpers (
              first_name,
              last_name,
              email,
              phone,
              skill,
              experience,
              barangay
            ),
            job_postings (
              title
            )
          ''')
          .eq('id', applicationId)
          .single();

      return _mapToApplicationWithDetails(response);
    } catch (e) {
      throw Exception('Failed to fetch application: $e');
    }
  }

  /// Get application count for a job posting
  static Future<int> getApplicationCount(String jobPostingId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('id')
          .eq('job_posting_id', jobPostingId);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get application count: $e');
    }
  }

  // Helper methods to map database response to Application model
  static Application _mapToApplication(Map<String, dynamic> data) {
    return Application(
      id: data['id'] as String,
      jobId: data['job_posting_id'] as String,
      jobTitle: '', // Will be filled when needed
      helperId: data['helper_id'] as String,
      helperName: '', // Will be filled when needed
      helperLocation: '', // Will be filled when needed
      coverLetter: data['cover_letter'] as String,
      appliedDate: DateTime.parse(data['applied_at'] as String),
      status: data['status'] as String,
      helperSkills: [], // Will be filled when needed
      helperExperience: '', // Will be filled when needed
    );
  }

  static Application _mapToApplicationWithDetails(Map<String, dynamic> data) {
    final helper = data['helpers'] as Map<String, dynamic>;
    final jobPosting = data['job_postings'] as Map<String, dynamic>;

    return Application(
      id: data['id'] as String,
      jobId: data['job_posting_id'] as String,
      jobTitle: jobPosting['title'] as String,
      helperId: data['helper_id'] as String,
      helperName: '${helper['first_name']} ${helper['last_name']}',
      helperEmail: helper['email'] as String?,
      helperPhone: helper['phone'] as String?,
      helperLocation: helper['barangay'] as String,
      coverLetter: data['cover_letter'] as String,
      appliedDate: DateTime.parse(data['applied_at'] as String),
      status: data['status'] as String,
      helperSkills: [helper['skill'] as String], // For now, single skill
      helperExperience: helper['experience'] as String,
    );
  }

  static Application _mapToApplicationWithJobDetails(
    Map<String, dynamic> data,
  ) {
    final jobPosting = data['job_postings'] as Map<String, dynamic>;

    return Application(
      id: data['id'] as String,
      jobId: data['job_posting_id'] as String,
      jobTitle: jobPosting['title'] as String,
      helperId: data['helper_id'] as String,
      helperName: '', // Not needed for helper's own applications
      helperLocation: '', // Not needed for helper's own applications
      coverLetter: data['cover_letter'] as String,
      appliedDate: DateTime.parse(data['applied_at'] as String),
      status: data['status'] as String,
      helperSkills: [],
      helperExperience: '',
    );
  }
}
