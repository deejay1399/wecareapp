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
      print(
        'DEBUG: Attempting to apply for job - jobPostingId: $jobPostingId, helperId: $helperId',
      );
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

      print(
        'DEBUG: Application successfully inserted with ID: ${response['id']}',
      );

      final applicationId = response['id'] as String;

      // Get job details to notify employer
      String jobTitle = '';
      try {
        final jobResponse = await SupabaseService.client
            .from('job_postings')
            .select('employer_id, title')
            .eq('id', jobPostingId)
            .single();

        final employerId = jobResponse['employer_id'] as String;
        jobTitle = jobResponse['title'] as String;

        print('DEBUG: Creating notification for employer: $employerId');
        print('DEBUG: Job title: $jobTitle');

        await NotificationService.createNotification(
          recipientId: employerId,
          title: 'New Application',
          body: '$helperName applied for "$jobTitle"',
          type: 'job_application',
          category: 'new',
          targetId: jobPostingId,
        );
        print(
          'DEBUG: Notification created successfully for employer: $employerId',
        );
      } catch (e) {
        print('ERROR creating application notification: $e');
        print('Error stack trace: ${StackTrace.current}');
      }

      try {
        print(
          'DEBUG: Creating confirmation notification for helper: $helperId',
        );
        await NotificationService.createNotification(
          recipientId: helperId,
          title: 'Application Submitted',
          body: 'Your application for "$jobTitle" has been submitted',
          type: 'application_submitted',
          category: 'new',
          targetId: applicationId,
        );
        print('DEBUG: Helper confirmation notification created');
      } catch (e) {
        print('Error creating helper confirmation notification: $e');
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
      print('DEBUG: Updating application $applicationId status to $status');
      await SupabaseService.client
          .from(_tableName)
          .update({'status': status})
          .eq('id', applicationId);
      print('DEBUG: Application status updated successfully');

      // Create notification for helper
      if (status == 'accepted') {
        print('DEBUG: Creating acceptance notification for helper: $helperId');
        await NotificationService.createNotification(
          recipientId: helperId,
          title: 'Application Accepted! 🎉',
          body: 'Your application for "$jobTitle" has been accepted',
          type: 'application_accepted',
          category: 'new',
          targetId: applicationId,
        );
        print('DEBUG: Acceptance notification created');

        final jobId = appResponse['job_posting_id'] as String;

        await JobPostingService.assignHelperToJob(
          jobId: jobId,
          helperId: helperId,
          helperName: helperName,
        );

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
            print(
              'DEBUG: Creating rejection notification for helper: ${app['helper_id']}',
            );
            await NotificationService.createNotification(
              recipientId: app['helper_id'] as String,
              title: 'Application Not Selected',
              body: 'We chose another candidate for "$jobTitle"',
              type: 'application_rejected',
              category: 'previous',
              targetId: app['id'] as String,
            );
            print(
              'DEBUG: Rejection notification created for ${app['helper_id']}',
            );
          } catch (e) {
            print('Error notifying rejected helper: $e');
          }
        }
      } else if (status == 'rejected') {
        // Direct rejection by employer
        print('DEBUG: Creating rejection notification for helper: $helperId');
        await NotificationService.createNotification(
          recipientId: helperId,
          title: 'Application Not Selected',
          body:
              'Unfortunately, your application for "$jobTitle" was not selected',
          type: 'application_rejected',
          category: 'previous',
          targetId: applicationId,
        );
        print('DEBUG: Rejection notification created');
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

  /// Get application by ID with fallback - tries to find by ID, then by job posting
  static Future<Application> getApplicationByIdWithFallback(
    String applicationId,
  ) async {
    try {
      print(
        'DEBUG ApplicationService: Fetching application with ID: $applicationId',
      );
      // First try direct fetch
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
          .maybeSingle();

      if (response != null) {
        print(
          'DEBUG ApplicationService: Successfully fetched application: $response',
        );
        return _mapToApplicationWithDetails(response);
      }

      print(
        'ERROR ApplicationService: Application with ID $applicationId not found, trying alternative lookup',
      );

      // Fallback: The applicationId might actually be a different identifier
      // Try to get the most recent application (it might be a new record)
      print(
        'DEBUG ApplicationService: Attempting to find application by recent timestamp',
      );
      final recentApplications = await SupabaseService.client
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
          .order('applied_at', ascending: false)
          .limit(1);

      if (recentApplications.isNotEmpty) {
        print('DEBUG ApplicationService: Found recent application as fallback');
        return _mapToApplicationWithDetails(recentApplications[0]);
      }

      throw Exception('Application not found');
    } catch (e) {
      print('ERROR ApplicationService: Failed to fetch application: $e');
      throw Exception('Failed to fetch application: $e');
    }
  }

  /// Get application by ID
  static Future<Application> getApplicationById(String applicationId) async {
    try {
      print(
        'DEBUG ApplicationService: Fetching application with ID: $applicationId',
      );
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
          .maybeSingle();

      if (response == null) {
        print(
          'ERROR ApplicationService: Application with ID $applicationId not found',
        );
        throw Exception('Application not found');
      }

      print(
        'DEBUG ApplicationService: Successfully fetched application: $response',
      );
      return _mapToApplicationWithDetails(response);
    } catch (e) {
      print('ERROR ApplicationService: Failed to fetch application: $e');
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
