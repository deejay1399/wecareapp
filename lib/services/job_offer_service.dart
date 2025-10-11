import '../models/job_offer.dart';
import '../services/supabase_service.dart';
import '../services/job_posting_service.dart';
import '../services/helper_service_posting_service.dart';

class JobOfferService {
  static const String _tableName = 'job_offers';

  /// Create a job offer in the messaging system
  static Future<JobOffer> createJobOffer({
    required String conversationId,
    required String employerId,
    required String helperId,
    required String servicePostingId,
    required String title,
    required String description,
    required double salary,
    required String paymentFrequency,
    required String municipality,
    required String location,
    required List<String> requiredSkills,
  }) async {
    try {
      final jobOffer = JobOffer(
        id: '',
        conversationId: conversationId,
        employerId: employerId,
        helperId: helperId,
        servicePostingId: servicePostingId,
        title: title,
        description: description,
        salary: salary,
        paymentFrequency: paymentFrequency,
        municipality: municipality,
        location: location,
        requiredSkills: requiredSkills,
        status: JobOfferStatus.pending,
        createdAt: DateTime.now(),
      );

      final response = await SupabaseService.client
          .from(_tableName)
          .insert(jobOffer.toInsertMap())
          .select()
          .single();

      return JobOffer.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create job offer: $e');
    }
  }

  /// Accept a job offer
  static Future<JobOffer> acceptJobOffer(String jobOfferId) async {
    try {
      // Get the job offer details
      final offerResponse = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('id', jobOfferId)
          .single();

      final jobOffer = JobOffer.fromMap(offerResponse);

      // Update job offer status to accepted
      await SupabaseService.client
          .from(_tableName)
          .update({
            'status': JobOfferStatus.accepted.name,
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobOfferId);

      // Convert payment frequency to match database constraints
      String dbPaymentFrequency = _convertPaymentFrequencyForDb(
        jobOffer.paymentFrequency,
      );

      // Create a job posting from the accepted offer
      final jobPosting = await JobPostingService.createJobPosting(
        employerId: jobOffer.employerId,
        title: jobOffer.title,
        description: jobOffer.description,
        salary: jobOffer.salary,
        paymentFrequency: dbPaymentFrequency,
        municipality: jobOffer.municipality,
        barangay: jobOffer.location,
        requiredSkills: jobOffer.requiredSkills,
      );

      // Get helper name from helper table
      final helperResponse = await SupabaseService.client
          .from('helpers')
          .select('first_name, last_name')
          .eq('id', jobOffer.helperId)
          .single();

      final helperName =
          '${helperResponse['first_name']} ${helperResponse['last_name']}';

      // Immediately assign the helper to the job (since they accepted)
      await JobPostingService.assignHelperToJob(
        jobId: jobPosting.id,
        helperId: jobOffer.helperId,
        helperName: helperName,
      );

      // Pause the helper's service posting since they're now hired
      await HelperServicePostingService.updateServicePostingStatus(
        jobOffer.servicePostingId,
        'paused',
      );

      // Return the updated job offer
      return jobOffer.copyWith(
        status: JobOfferStatus.accepted,
        respondedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to accept job offer: $e');
    }
  }

  /// Helper method to convert payment frequency from UI format to database format
  static String _convertPaymentFrequencyForDb(String paymentFrequency) {
    switch (paymentFrequency.toLowerCase()) {
      case 'hourly':
        return 'Per Hour';
      case 'daily':
        return 'Per Day';
      case 'weekly':
        return 'Per Week';
      case 'monthly':
        return 'Per Month';
      case 'one-time':
        return 'Per Day'; // Default to per day for one-time jobs
      default:
        return 'Per Hour'; // Safe default
    }
  }

  /// Reject a job offer
  static Future<JobOffer> rejectJobOffer(
    String jobOfferId,
    String rejectionReason,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .update({
            'status': JobOfferStatus.rejected.name,
            'responded_at': DateTime.now().toIso8601String(),
            'rejection_reason': rejectionReason,
          })
          .eq('id', jobOfferId)
          .select()
          .single();

      return JobOffer.fromMap(response);
    } catch (e) {
      throw Exception('Failed to reject job offer: $e');
    }
  }

  /// Get job offers for a conversation
  static Future<List<JobOffer>> getJobOffersForConversation(
    String conversationId,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false);

      return (response as List).map((data) => JobOffer.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch job offers: $e');
    }
  }

  /// Get pending job offers for a helper
  static Future<List<JobOffer>> getPendingJobOffersForHelper(
    String helperId,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('helper_id', helperId)
          .eq('status', JobOfferStatus.pending.name)
          .order('created_at', ascending: false);

      return (response as List).map((data) => JobOffer.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending job offers: $e');
    }
  }

  /// Get job offers sent by an employer
  static Future<List<JobOffer>> getJobOffersByEmployer(
    String employerId,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('employer_id', employerId)
          .order('created_at', ascending: false);

      return (response as List).map((data) => JobOffer.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch employer job offers: $e');
    }
  }

  /// Get job offer by ID
  static Future<JobOffer?> getJobOfferById(String jobOfferId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('id', jobOfferId)
          .maybeSingle();

      if (response == null) return null;
      return JobOffer.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch job offer: $e');
    }
  }

  /// Check if there's a pending job offer in conversation
  static Future<JobOffer?> getPendingJobOfferInConversation(
    String conversationId,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('conversation_id', conversationId)
          .eq('status', JobOfferStatus.pending.name)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return JobOffer.fromMap(response);
    } catch (e) {
      return null;
    }
  }
}
