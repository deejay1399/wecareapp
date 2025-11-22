import 'package:flutter/material.dart';
import '../../models/application.dart';
import '../../models/job_posting.dart';
import '../../models/employer.dart';
import '../../models/rating_statistics.dart';
import '../../services/job_posting_service.dart';
import '../../services/employer_auth_service.dart';
import '../../services/application_service.dart';
import '../../services/database_messaging_service.dart';
import '../../services/session_service.dart';
import '../../services/rating_service.dart';
import '../messaging/chat_screen.dart';
import '../../widgets/rating/star_rating_display.dart';
import '../../localization_manager.dart';

class HelperApplicationDetailsScreen extends StatefulWidget {
  final Application application;

  const HelperApplicationDetailsScreen({super.key, required this.application});

  @override
  State<HelperApplicationDetailsScreen> createState() =>
      _HelperApplicationDetailsScreenState();
}

class _HelperApplicationDetailsScreenState
    extends State<HelperApplicationDetailsScreen> {
  late Application _application;
  JobPosting? _jobPosting;
  Employer? _employer;
  RatingStatistics? _employerRatingStats;
  bool _isLoading = true;
  bool _isWithdrawing = false;
  final _ratingService = RatingService();

  @override
  void initState() {
    super.initState();
    _application = widget.application;
    _loadJobAndEmployerDetails();
  }

  Future<void> _loadJobAndEmployerDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load job posting details
      final jobPosting = await JobPostingService.getJobPostingById(
        _application.jobId,
      );

      // Load employer details
      final employer = await EmployerAuthService.getEmployerById(
        jobPosting.employerId,
      );

      // Load employer rating statistics
      final employerRatingStats = await _ratingService.getUserRatingStatistics(
        jobPosting.employerId,
        'employer',
      );

      if (mounted) {
        setState(() {
          _jobPosting = jobPosting;
          _employer = employer;
          _employerRatingStats = employerRatingStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _withdrawApplication() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(LocalizationManager.translate('withdraw_application')),
            content: Text(
              LocalizationManager.translate(
                'withdraw_application_confirmation',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(LocalizationManager.translate('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(LocalizationManager.translate('withdraw')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isWithdrawing = true;
    });

    try {
      await ApplicationService.updateApplicationStatus(
        _application.id,
        'withdrawn',
      );

      if (mounted) {
        setState(() {
          _application = Application(
            id: _application.id,
            jobId: _application.jobId,
            jobTitle: _application.jobTitle,
            helperId: _application.helperId,
            helperName: _application.helperName,
            helperProfileImage: _application.helperProfileImage,
            helperLocation: _application.helperLocation,
            coverLetter: _application.coverLetter,
            appliedDate: _application.appliedDate,
            status: LocalizationManager.translate('withdrawn'),
            helperPhone: _application.helperPhone,
            helperEmail: _application.helperEmail,
            helperSkills: _application.helperSkills,
            helperExperience: _application.helperExperience,
          );
          _isWithdrawing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translate(
                'application_withdrawn_successfully',
              ),
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        // Return updated application
        Navigator.pop(context, _application);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isWithdrawing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationManager.translate('failed_to_withdraw_application')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startChat() async {
    if (_employer == null || _jobPosting == null) return;

    try {
      final currentUserId = await SessionService.getCurrentUserId();
      if (currentUserId == null) return;

      final currentHelper = await SessionService.getCurrentHelper();
      if (currentHelper == null) return;

      // Create or get conversation
      final conversation =
          await DatabaseMessagingService.createOrGetConversation(
            employerId: _employer!.id,
            employerName: _employer!.fullName,
            helperId: currentUserId,
            helperName: currentHelper.fullName,
            jobId: _application.jobId,
            jobTitle: _application.jobTitle,
          );

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversation: conversation,
              currentUserId: currentUserId,
            ),
          ),
        );
        // When returning from chat, we stay on the application details screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationManager.translate('failed_to_start_chat')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor() {
    switch (_application.status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'accepted':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFF87171);
      case 'withdrawn':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _application.jobTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${LocalizationManager.translate('applied')}: ${_application.formatAppliedDate()}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor().withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _application.statusDisplayText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobInfo() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF8A50)),
        ),
      );
    }

    if (_jobPosting == null || _employer == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Text(
          LocalizationManager.translate('job_information_not_available'),
          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationManager.translate('job_information'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),

          // Employer Info
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.business,
                  size: 30,
                  color: Color(0xFFFF8A50),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _employer!.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      _jobPosting!.barangay,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_employerRatingStats != null &&
                        _employerRatingStats!.hasRatings) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Color(0xFFFFC107),
                          ),
                          const SizedBox(width: 4),
                          StarRatingDisplay(
                            rating: _employerRatingStats!.averageRating,
                            totalRatings: _employerRatingStats!.totalRatings,
                            size: 14,
                          ),
                        ],
                      ),
                    ] else if (_employerRatingStats != null) ...[
                      Text(
                        LocalizationManager.translate('no_ratings_yet'),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Job Details
          _buildInfoRow(
            LocalizationManager.translate('salary'),
            '₱${_jobPosting!.salary.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            LocalizationManager.translate('payment'),
            _jobPosting!.paymentFrequency,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            LocalizationManager.translate('status'),
            _jobPosting!.status,
          ),

          const SizedBox(height: 20),

          // Job Description
          Text(
            LocalizationManager.translate('job_description'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: Text(
              _jobPosting!.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Required Skills
          Text(
            LocalizationManager.translate('required_skills'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _jobPosting!.requiredSkills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF8A50).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    color: Color(0xFFFF8A50),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverLetter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationManager.translate('your_applicants_message'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: Text(
              _application.coverLetter.isNotEmpty
                  ? _application.coverLetter
                  : LocalizationManager.translate(
                      'no_applicants_message_provided',
                    ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        children: [
          // Message Employer Button (only if accepted)
          if (_application.status == 'accepted') ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _startChat,
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: Text(
                  LocalizationManager.translate('message_employer'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Withdraw Button (only if pending)
          if (_application.status == 'pending')
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _isWithdrawing ? null : _withdrawApplication,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF87171),
                  side: const BorderSide(color: Color(0xFFF87171)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isWithdrawing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFF87171),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            LocalizationManager.translate('withdrawing'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        LocalizationManager.translate('withdraw_application'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

          // Status-based informational text
          if (_application.status == 'rejected') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFFF87171),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      LocalizationManager.translate('application_not_accepted'),
                      style: TextStyle(fontSize: 14, color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_application.status == 'withdrawn') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF6B7280),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      LocalizationManager.translate(
                        'withdrawn_application_message',
                      ),
                      style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8A50)),
        ),
        title: Text(
          LocalizationManager.translate('application_details'),
          style: TextStyle(
            color: Color(0xFFFF8A50),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildJobInfo(),
              const SizedBox(height: 24),
              _buildCoverLetter(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
