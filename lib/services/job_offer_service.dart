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

      String dbPaymentFrequency = _convertPaymentFrequencyForDb(
        jobOffer.paymentFrequency,
      );

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

      final helperResponse = await SupabaseService.client
          .from('helpers')
          .select('first_name, last_name')
          .eq('id', jobOffer.helperId)
          .single();

      final helperName =
          '${helperResponse['first_name']} ${helperResponse['last_name']}';

      await JobPostingService.assignHelperToJob(
        jobId: jobPosting.id,
        helperId: jobOffer.helperId,
        helperName: helperName,
      );

      await HelperServicePostingService.updateServicePostingStatus(
        jobOffer.servicePostingId,
        'paused',
      );

      return jobOffer.copyWith(
        status: JobOfferStatus.accepted,
        respondedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to accept job offer: $e');
    }
  }

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
        return 'Per Day';
      default:
        return 'Per Hour';
    }
  }

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
