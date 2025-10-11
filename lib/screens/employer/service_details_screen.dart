import 'package:flutter/material.dart';
import '../../models/helper_service_posting.dart';
import '../../models/rating_statistics.dart';
import '../../services/helper_service_posting_service.dart';
import '../../services/database_messaging_service.dart';
import '../../services/session_service.dart';
import '../../services/rating_service.dart';
import '../../services/job_offer_service.dart';
import '../../widgets/rating/star_rating_display.dart';

import '../messaging/chat_screen.dart';
import '../rating/user_ratings_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final HelperServicePosting servicePosting;

  const ServiceDetailsScreen({super.key, required this.servicePosting});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final _ratingService = RatingService();
  bool _isContactingHelper = false;
  RatingStatistics? _helperRatingStats;

  @override
  void initState() {
    super.initState();
    // Increment view count when screen is opened
    _incrementViewCount();
    // Load helper rating statistics
    _loadHelperRatingStats();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _incrementViewCount() async {
    try {
      // Get current employer info
      final currentEmployer = await SessionService.getCurrentEmployer();
      if (currentEmployer != null) {
        await HelperServicePostingService.incrementViewsCount(
          widget.servicePosting.id,
          currentEmployer.id,
          'employer',
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadHelperRatingStats() async {
    try {
      final stats = await _ratingService.getUserRatingStatistics(
        widget.servicePosting.helperId,
        'helper',
      );

      if (mounted) {
        setState(() {
          _helperRatingStats = stats;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _contactHelper() async {
    // Show job offer dialog instead of just sending a message
    await _showJobOfferDialog();
  }

  Future<void> _showJobOfferDialog() async {
    final titleController = TextEditingController(
      text: widget.servicePosting.title,
    );
    final descriptionController = TextEditingController(
      text: _messageController.text.trim(),
    );
    final salaryController = TextEditingController();
    final locationController = TextEditingController();
    String paymentFrequency = 'hourly';
    List<String> requiredSkills = [...widget.servicePosting.skills];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Send Job Offer to ${widget.servicePosting.helperName}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Job Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Job Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: salaryController,
                          decoration: const InputDecoration(
                            labelText: 'Salary Amount',
                            border: OutlineInputBorder(),
                            prefixText: '₱',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: paymentFrequency,
                          decoration: const InputDecoration(
                            labelText: 'Payment',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'hourly',
                              child: Text('Per Hour'),
                            ),
                            DropdownMenuItem(
                              value: 'daily',
                              child: Text('Per Day'),
                            ),
                            DropdownMenuItem(
                              value: 'weekly',
                              child: Text('Per Week'),
                            ),
                            DropdownMenuItem(
                              value: 'monthly',
                              child: Text('Per Month'),
                            ),
                            DropdownMenuItem(
                              value: 'one-time',
                              child: Text('One-time'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => paymentFrequency = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Job Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty ||
                    salaryController.text.trim().isEmpty ||
                    locationController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Job Offer'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _createAndSendJobOffer(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        salary: double.tryParse(salaryController.text.trim()) ?? 0,
        paymentFrequency: paymentFrequency,
        municipality: "testhello",
        location: locationController.text.trim(),
        requiredSkills: requiredSkills,
      );
    }

    titleController.dispose();
    descriptionController.dispose();
    salaryController.dispose();
    locationController.dispose();
  }

  Future<void> _createAndSendJobOffer({
    required String title,
    required String description,
    required double salary,
    required String paymentFrequency,
    required String municipality,
    required String location,
    required List<String> requiredSkills,
  }) async {
    setState(() {
      _isContactingHelper = true;
    });

    try {
      // Get current employer info
      final currentEmployer = await SessionService.getCurrentEmployer();
      if (currentEmployer == null) {
        throw Exception('Employer session not found');
      }

      // Create or get conversation
      final conversation =
          await DatabaseMessagingService.createOrGetConversation(
            employerId: currentEmployer.id,
            employerName:
                '${currentEmployer.firstName} ${currentEmployer.lastName}',
            helperId: widget.servicePosting.helperId,
            helperName: widget.servicePosting.helperName,
            jobId: widget.servicePosting.id,
            jobTitle: 'Service: ${widget.servicePosting.title}',
          );

      // Create the job offer
      await JobOfferService.createJobOffer(
        conversationId: conversation.id,
        employerId: currentEmployer.id,
        helperId: widget.servicePosting.helperId,
        servicePostingId: widget.servicePosting.id,
        title: title,
        description: description,
        salary: salary,
        paymentFrequency: paymentFrequency,
        municipality: municipality,
        location: location,
        requiredSkills: requiredSkills,
      );

      // Send an initial message about the job offer
      await DatabaseMessagingService.sendMessage(
        conversationId: conversation.id,
        content:
            'I\'ve sent you a job offer! Please check the details above and let me know if you\'re interested.',
      );

      // Increment contacts count
      await HelperServicePostingService.incrementContactsCount(
        widget.servicePosting.id,
      );

      if (mounted) {
        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversation: conversation,
              currentUserId: currentEmployer.id,
            ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job offer sent! Opening chat...'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        // Clear the message field
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send job offer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isContactingHelper = false;
        });
      }
    }
  }

  Widget _buildHelperProfile() {
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
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.handyman,
                  color: Color(0xFFFF8A50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.servicePosting.helperName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Helper Profile',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserRatingsScreen(
                        userId: widget.servicePosting.helperId,
                        userType: 'helper',
                        userName: widget.servicePosting.helperName,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF8A50),
                  side: const BorderSide(color: Color(0xFFFF8A50), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Reviews',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_helperRatingStats != null) ...[
            if (_helperRatingStats!.hasRatings) ...[
              StarRatingDisplay(
                rating: _helperRatingStats!.averageRating,
                totalRatings: _helperRatingStats!.totalRatings,
                size: 20,
              ),
            ] else ...[
              Text(
                'No ratings yet',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ] else ...[
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ],
      ),
    );
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
          // Title and status
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.servicePosting.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.servicePosting.statusColor.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.servicePosting.statusColor.withValues(
                      alpha: 0.3,
                    ),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.servicePosting.statusDisplayText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.servicePosting.statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Rate and availability
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.servicePosting.formatRate(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.servicePosting.availability,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Experience level
          Row(
            children: [
              const Icon(
                Icons.star_outline,
                size: 20,
                color: Color(0xFFFFC107),
              ),
              const SizedBox(width: 8),
              Text(
                'Experience: ${widget.servicePosting.experienceLevel}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
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
          const Text(
            'Service Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.servicePosting.description,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkills() {
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
          const Text(
            'Helper\'s Expertise',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.servicePosting.skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceAreas() {
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
          const Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 20,
                color: Color(0xFF6B7280),
              ),
              SizedBox(width: 8),
              Text(
                'Service Areas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.servicePosting.serviceAreas.map((area) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF8A50).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  area,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF8A50),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
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
          const Text(
            'Service Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.visibility_outlined,
                  '${widget.servicePosting.viewsCount}',
                  'Views',
                  const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.message_outlined,
                  '${widget.servicePosting.contactsCount}',
                  'Contacts',
                  const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.schedule,
                  widget.servicePosting.formatCreatedDate().replaceAll(
                    'Created ',
                    '',
                  ),
                  'Posted',
                  const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
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
          const Text(
            'Send Job Offer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Interested in hiring this helper? Send them a formal job offer with your requirements.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Describe your job requirements and what you need help with...',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1565C0),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isContactingHelper ? null : _contactHelper,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isContactingHelper
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isContactingHelper ? 'Sending Job Offer...' : 'Send Job Offer',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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
        title: const Text(
          'Service Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1565C0)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildHelperProfile(),
              const SizedBox(height: 24),
              _buildDescription(),
              const SizedBox(height: 24),
              _buildSkills(),
              const SizedBox(height: 24),
              _buildServiceAreas(),
              const SizedBox(height: 24),
              _buildStats(),
              const SizedBox(height: 24),
              _buildContactSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
