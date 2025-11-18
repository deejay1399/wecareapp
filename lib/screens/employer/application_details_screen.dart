import 'package:flutter/material.dart';
import '../../models/application.dart';
import '../../services/helper_auth_service.dart';
import '../../services/application_service.dart';
import '../../services/database_messaging_service.dart';
import '../../services/session_service.dart';
import '../messaging/chat_screen.dart';
import '../../localization_manager.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final Application application;

  const ApplicationDetailsScreen({super.key, required this.application});

  @override
  State<ApplicationDetailsScreen> createState() =>
      _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  late Application _application;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _application = widget.application;
    _loadHelperDetails();
    _setDefaultMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _setDefaultMessage() {
    _messageController.text = LocalizationManager.translate(
      'default_accept_message',
    );
  }

  Future<void> _loadHelperDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await HelperAuthService.getHelperById(_application.helperId);

      if (mounted) {
        setState(() {
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

  Future<void> _updateApplicationStatus(String status) async {
    if (status == 'accepted') {
      final message = _messageController.text.trim();
      if (message.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translate('please_enter_message'),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await ApplicationService.updateApplicationStatus(_application.id, status);

      // If accepted with message, create conversation and send message
      if (status == 'accepted') {
        await _sendAcceptanceMessage(_messageController.text.trim());
      }

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
            status: status,
            helperPhone: _application.helperPhone,
            helperEmail: _application.helperEmail,
            helperSkills: _application.helperSkills,
            helperExperience: _application.helperExperience,
          );
          _isUpdatingStatus = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationManager.translate("application")} $status ${LocalizationManager.translate("successfully")}',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );

        // Return updated application
        Navigator.pop(context, _application);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationManager.translate("failed_to_update_application")}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsComplete() async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await ApplicationService.updateApplicationStatus(
        _application.id,
        'completed',
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
            status: 'completed',
            helperPhone: _application.helperPhone,
            helperEmail: _application.helperEmail,
            helperSkills: _application.helperSkills,
            helperExperience: _application.helperExperience,
          );
          _isUpdatingStatus = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translate('marked_as_complete_success'),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );

        Navigator.pop(context, _application);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationManager.translate("failed_to_mark_complete")}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendAcceptanceMessage(String message) async {
    try {
      final currentUserId = await SessionService.getCurrentUserId();
      if (currentUserId == null) return;

      final currentEmployer = await SessionService.getCurrentEmployer();
      if (currentEmployer == null) return;

      // Create or get conversation
      final conversation =
          await DatabaseMessagingService.createOrGetConversation(
            employerId: currentUserId,
            employerName: currentEmployer.fullName,
            helperId: _application.helperId,
            helperName: _application.helperName,
            jobId: _application.jobId,
            jobTitle: _application.jobTitle,
          );

      // Send the acceptance message
      await DatabaseMessagingService.sendMessage(
        conversationId: conversation.id,
        content: message,
      );
    } catch (e) {
      // Handle error silently for message sending
    }
  }

  Future<void> _startChat() async {
    try {
      final currentUserId = await SessionService.getCurrentUserId();
      if (currentUserId == null) return;

      final currentEmployer = await SessionService.getCurrentEmployer();
      if (currentEmployer == null) return;

      // Create or get conversation
      final conversation =
          await DatabaseMessagingService.createOrGetConversation(
            employerId: currentUserId,
            employerName: currentEmployer.fullName,
            helperId: _application.helperId,
            helperName: _application.helperName,
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
              '${LocalizationManager.translate("failed_to_start_chat")}: $e',
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
      case 'completed':
        return const Color(0xFF3B82F6);
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
                      '${LocalizationManager.translate("applied")} ${_application.formatAppliedDate()}',
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

  Widget _buildHelperInfo() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1565C0)),
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
            LocalizationManager.translate('helper_information'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),

          // Helper Name and Rating
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _application.helperName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      _application.helperLocation,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LocalizationManager.translate('available_for_hire'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Contact Information
          if (_application.helperEmail != null) ...[
            _buildInfoRow(
              LocalizationManager.translate('email'),
              _application.helperEmail!,
            ),
            const SizedBox(height: 12),
          ],
          if (_application.helperPhone != null) ...[
            _buildInfoRow(
              LocalizationManager.translate('phone'),
              _application.helperPhone!,
            ),
            const SizedBox(height: 12),
          ],
          _buildInfoRow(
            LocalizationManager.translate('experience'),
            _application.helperExperience,
          ),

          const SizedBox(height: 20),

          // Skills
          Text(
            LocalizationManager.translate('skills'),
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
            children: _application.helperSkills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
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

  Widget _buildApplicationInfo() {
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
            LocalizationManager.translate('applicant_message'),
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
                  : LocalizationManager.translate('no_applicant_message'),
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

  Widget _buildAcceptanceMessage() {
    if (_application.status != 'pending') return const SizedBox.shrink();

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
              Icon(
                Icons.message_outlined,
                color: const Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocalizationManager.translate('acceptance_message'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            LocalizationManager.translate('write_acceptance_message'),
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: LocalizationManager.translate('enter_message_here'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF10B981),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: _setDefaultMessage,
                icon: const Icon(
                  Icons.refresh,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                label: Text(
                  LocalizationManager.translate('use_default_message'),
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_application.status == 'pending') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isUpdatingStatus
                    ? null
                    : () => _updateApplicationStatus('accepted'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUpdatingStatus
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            LocalizationManager.translate('processing'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        LocalizationManager.translate('accept_application'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _isUpdatingStatus
                    ? null
                    : () => _updateApplicationStatus('rejected'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF87171),
                  side: const BorderSide(color: Color(0xFFF87171)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  LocalizationManager.translate('reject_application'),
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

    if (_application.status == 'accepted') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _startChat,
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: Text(
                  LocalizationManager.translate('message_helper'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isUpdatingStatus ? null : _markAsComplete,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  LocalizationManager.translate('mark_as_completed'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_application.status == 'completed') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Text(
          LocalizationManager.translate('application_already_completed'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
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
      child: Text(
        LocalizationManager.translate('application_rejected_info'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1565C0)),
        ),
        title: Text(
          LocalizationManager.translate('application_details'),
          style: TextStyle(
            color: Color(0xFF1565C0),
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
              _buildHelperInfo(),
              const SizedBox(height: 24),
              _buildApplicationInfo(),
              const SizedBox(height: 24),
              _buildAcceptanceMessage(),
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
