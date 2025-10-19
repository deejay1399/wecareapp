import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/job_posting.dart';
import '../../models/application.dart';
import '../../services/job_posting_service.dart';
import '../../services/application_service.dart';
import '../../utils/constants/payment_frequency_constants.dart';
import '../../widgets/cards/application_card.dart';
import 'edit_job_screen.dart';
import 'application_details_screen.dart';
import '../../localization_manager.dart';

class JobDetailsScreen extends StatefulWidget {
  final JobPosting jobPosting;

  const JobDetailsScreen({super.key, required this.jobPosting});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  late JobPosting _jobPosting;
  List<Application> _applications = [];
  bool _isLoadingApplications = true;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _jobPosting = widget.jobPosting;
    _loadApplications();

    // Refresh applications every 30 seconds when screen is visible
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadApplications();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoadingApplications = true;
    });

    try {
      final applications = await ApplicationService.getApplicationsForJob(
        _jobPosting.id,
      );

      if (mounted) {
        setState(() {
          _applications = applications;
          _isLoadingApplications = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingApplications = false;
        });
      }
    }
  }

  Future<void> _editJob() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditJobScreen(jobPosting: _jobPosting),
      ),
    );

    if (result != null && result is JobPosting && mounted) {
      setState(() {
        _jobPosting = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationManager.translate('job_updated_successfully'),
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _updateJobStatus(String status) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final updatedJob = await JobPostingService.updateJobPostingStatus(
        _jobPosting.id,
        status,
      );

      if (mounted) {
        setState(() {
          _jobPosting = updatedJob;
          _isUpdatingStatus = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translate(
                status == 'active'
                    ? 'job_activated'
                    : 'job_${status.toLowerCase()}',
              ),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationManager.translate('failed_to_update_job_status')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteJob() async {
    // Show confirmation dialog
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(LocalizationManager.translate('delete_job_posting')),
            content: Text(
              LocalizationManager.translate(
                'are_you_sure_you_want_to_delete_this_job_posting',
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
                child: Text(LocalizationManager.translate('delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    try {
      await JobPostingService.deleteJobPosting(_jobPosting.id);

      if (mounted) {
        // Navigate back with deletion flag first
        Navigator.pop(context, 'deleted');
        // Show success message using the parent context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translate('job_posting_deleted_successfully'),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationManager.translate('failed_to_delete_job_posting')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onApplicationStatusChange(
    String applicationId,
    String newStatus,
  ) async {
    try {
      await ApplicationService.updateApplicationStatus(
        applicationId,
        newStatus,
      );

      // Refresh applications list
      _loadApplications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationManager.translate('application')} $newStatus ${LocalizationManager.translate('successfully')}',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationManager.translate('failed_to_update_application')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor() {
    switch (_jobPosting.status) {
      case 'active':
        return const Color(0xFF10B981);
      case 'paused':
        return const Color(0xFFFF9800);
      case 'closed':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusDisplayText() {
    switch (_jobPosting.status) {
      case 'active':
        return LocalizationManager.translate('active');
      case 'paused':
        return LocalizationManager.translate('paused');
      case 'closed':
        return LocalizationManager.translate('closed');
      default:
        return LocalizationManager.translate('unknown');
    }
  }

  Widget _buildJobInfo() {
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
                  _jobPosting.title,
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
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor().withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStatusDisplayText(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Location and salary
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                _jobPosting.barangay,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                '₱${_jobPosting.salary.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                PaymentFrequencyConstants.frequencyLabels[_jobPosting
                        .paymentFrequency] ??
                    _jobPosting.paymentFrequency,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            LocalizationManager.translate('job_description'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            _jobPosting.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // Required skills
          Text(
            LocalizationManager.translate('required_skills'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _jobPosting.requiredSkills.map((skill) {
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
                    color: Color(0xFF1565C0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Posted date
          Text(
            '${LocalizationManager.translate('posted')} ${_formatDate(_jobPosting.createdAt)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Edit button
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _editJob,
            icon: const Icon(Icons.edit, size: 18),
            label: Text(LocalizationManager.translate('edit_job')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Status button
        Expanded(
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteJob();
              } else {
                _updateJobStatus(value);
              }
            },
            enabled: !_isUpdatingStatus,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1565C0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isUpdatingStatus
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1565C0),
                      ),
                    )
                  : const Icon(Icons.more_vert, color: Color(0xFF1565C0)),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'active',
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_arrow,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(LocalizationManager.translate('activate')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'paused',
                child: Row(
                  children: [
                    const Icon(Icons.pause, color: Color(0xFFFF9800), size: 18),
                    const SizedBox(width: 8),
                    Text(LocalizationManager.translate('pause')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'closed',
                child: Row(
                  children: [
                    const Icon(Icons.stop, color: Color(0xFFF44336), size: 18),
                    const SizedBox(width: 8),
                    Text(LocalizationManager.translate('close')),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      LocalizationManager.translate('delete'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              LocalizationManager.translate('applications'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_applications.length} ${LocalizationManager.translate('applications')}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoadingApplications)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF1565C0)),
          )
        else if (_applications.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    size: 40,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  LocalizationManager.translate('no_applications_yet'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocalizationManager.translate('no_applications_description'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            children: _applications.map((application) {
              return ApplicationCard(
                application: application,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ApplicationDetailsScreen(application: application),
                    ),
                  );
                  if (result != null) {
                    _loadApplications();
                  }
                },
                onStatusChange: (status) =>
                    _onApplicationStatusChange(application.id, status),
              );
            }).toList(),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return LocalizationManager.translate('today');
    if (difference == 1) return LocalizationManager.translate('yesterday');
    if (difference < 7) {
      return LocalizationManager.translate(
        'days_ago',
      ).replaceAll('{days}', difference.toString());
    }
    if (difference < 30) {
      return LocalizationManager.translate(
        'weeks_ago',
      ).replaceAll('{weeks}', (difference ~/ 7).toString());
    }
    return LocalizationManager.translate(
      'months_ago',
    ).replaceAll('{months}', (difference ~/ 30).toString());
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
          LocalizationManager.translate('job_details'),
          style: const TextStyle(
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
              _buildJobInfo(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 32),
              _buildApplicationsSection(),
            ],
          ),
        ),
      ),
    );
  }
}
