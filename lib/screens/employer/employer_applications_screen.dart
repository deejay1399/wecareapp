import 'package:flutter/material.dart';
import '../../models/application.dart';
import '../../models/employer.dart';
import '../../services/application_service.dart';
import '../../services/job_posting_service.dart';
import '../../services/session_service.dart';
import '../../services/database_messaging_service.dart';
import '../../widgets/cards/application_card.dart';
import 'application_details_screen.dart';

class EmployerApplicationsScreen extends StatefulWidget {
  const EmployerApplicationsScreen({super.key});

  @override
  State<EmployerApplicationsScreen> createState() =>
      _EmployerApplicationsScreenState();
}

class _EmployerApplicationsScreenState
    extends State<EmployerApplicationsScreen> {
  List<Application> _applications = [];
  String _selectedFilter = 'all'; // 'all', 'pending', 'accepted', 'rejected'
  bool _isLoading = true;
  String? _errorMessage;
  Employer? _currentEmployer;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmployer();
  }

  Future<void> _loadCurrentEmployer() async {
    try {
      final employer = await SessionService.getCurrentEmployer();
      if (employer != null) {
        setState(() {
          _currentEmployer = employer;
        });
        await _loadApplications();
      } else {
        setState(() {
          _errorMessage = 'Failed to load employer information';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load employer information: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadApplications() async {
    if (_currentEmployer == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get all job postings for this employer
      final jobPostings = await JobPostingService.getJobPostingsByEmployer(
        _currentEmployer!.id,
      );

      // Get applications for all job postings
      List<Application> allApplications = [];
      for (final job in jobPostings) {
        final applications = await ApplicationService.getApplicationsForJob(
          job.id,
        );
        // Filter out withdrawn applications
        final nonWithdrawnApplications = applications
            .where((app) => !app.isWithdrawn)
            .toList();
        allApplications.addAll(nonWithdrawnApplications);
      }

      // Sort by applied date (newest first)
      allApplications.sort((a, b) => b.appliedDate.compareTo(a.appliedDate));

      if (mounted) {
        setState(() {
          _applications = allApplications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load applications: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onApplicationTap(Application application) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ApplicationDetailsScreen(application: application),
      ),
    );

    // If application was updated (accepted/rejected), refresh the list
    if (result != null) {
      _loadApplications();
    }
  }

  Future<void> _onStatusChange(
    Application application,
    String newStatus,
  ) async {
    if (newStatus == 'accepted') {
      // Show message dialog for acceptance
      await _showAcceptanceDialog(application);
    } else {
      // Direct rejection
      await _updateApplicationStatus(application, newStatus);
    }
  }

  Future<void> _showAcceptanceDialog(Application application) async {
    final messageController = TextEditingController();
    String? messageError;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Accept Application'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accept ${application.helperName}\'s application for "${application.jobTitle}"?',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Send a message to the helper:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Congratulations! Your application has been accepted. Please contact me at...',
                      border: const OutlineInputBorder(),
                      errorText: messageError,
                    ),
                    onChanged: (_) {
                      if (messageError != null) {
                        setState(() {
                          messageError = null;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (messageController.text.trim().isEmpty) {
                      setState(() {
                        messageError = 'Please enter a message for the helper';
                      });
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accept & Send'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && messageController.text.trim().isNotEmpty) {
      await _updateApplicationStatus(
        application,
        'accepted',
        messageController.text.trim(),
      );
    }

    messageController.dispose();
  }

  Future<void> _updateApplicationStatus(
    Application application,
    String status, [
    String? message,
  ]) async {
    try {
      await ApplicationService.updateApplicationStatus(application.id, status);

      // If application is accepted and message provided, create conversation and send message
      if (status == 'accepted' &&
          message != null &&
          message.trim().isNotEmpty) {
        final currentEmployer = await SessionService.getCurrentEmployer();
        if (currentEmployer != null) {
          try {
            // Create or get conversation for this job application
            final conversation =
                await DatabaseMessagingService.createOrGetConversation(
                  employerId: currentEmployer.id,
                  employerName:
                      '${currentEmployer.firstName} ${currentEmployer.lastName}',
                  helperId: application.helperId,
                  helperName: application.helperName,
                  jobId: application.jobId,
                  jobTitle: application.jobTitle,
                );

            // Send the acceptance message
            await DatabaseMessagingService.sendMessage(
              conversationId: conversation.id,
              content: message,
            );
          } catch (e) {
            // Log messaging error but don't fail the acceptance
            debugPrint('Failed to send acceptance message: $e');
          }
        }
      }

      // Refresh applications list
      await _loadApplications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? 'Application accepted and message sent to helper!'
                  : 'Application ${status}ed successfully',
            ),
            backgroundColor: status == 'accepted'
                ? const Color(0xFF4CAF50)
                : const Color(0xFFF44336),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Application> get _filteredApplications {
    if (_selectedFilter == 'all') return _applications;
    return _applications.where((app) => app.status == _selectedFilter).toList();
  }

  int get _pendingCount => _applications.where((app) => app.isPending).length;
  int get _acceptedCount => _applications.where((app) => app.isAccepted).length;
  int get _rejectedCount => _applications.where((app) => app.isRejected).length;

  Widget _buildFilterChip(String filter, String label, int count) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1565C0)
              : const Color(0xFF1565C0).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(
              0xFF1565C0,
            ).withValues(alpha: isSelected ? 1.0 : 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF1565C0),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFF1565C0).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 60,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Applications Yets',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Once you post jobs, helper applications will appear here for you to review and manage.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            // Benefits list
            Column(
              children: [
                _buildBenefitItem(
                  Icons.person_search,
                  'Review helper profiles and ratings',
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  Icons.chat_bubble_outline,
                  'Read Applicant\'s message and experience',
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  Icons.thumb_up_outlined,
                  'Accept or reject applications easily',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1565C0)),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(List<Application> filteredApplications) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1565C0)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Error Loading Applications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadApplications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_applications.isEmpty) {
      return _buildEmptyState();
    }

    if (filteredApplications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No $_selectedFilter applications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: const Color(0xFF1565C0),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: filteredApplications.length,
        itemBuilder: (context, index) {
          return ApplicationCard(
            application: filteredApplications[index],
            onTap: () => _onApplicationTap(filteredApplications[index]),
            onStatusChange: (status) =>
                _onStatusChange(filteredApplications[index], status),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredApplications = _filteredApplications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Applications',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                  if (_applications.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_applications.length} Total',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Filter chips
            if (_applications.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('all', 'All', _applications.length),
                    const SizedBox(width: 12),
                    _buildFilterChip('pending', 'Pending', _pendingCount),
                    const SizedBox(width: 12),
                    _buildFilterChip('accepted', 'Accepted', _acceptedCount),
                    const SizedBox(width: 12),
                    _buildFilterChip('rejected', 'Rejected', _rejectedCount),
                  ],
                ),
              ),

            // Content
            Expanded(child: _buildContent(filteredApplications)),
          ],
        ),
      ),
    );
  }
}
