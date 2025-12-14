import 'package:flutter/material.dart';
import '../../models/job_posting.dart';
import '../../services/job_posting_service.dart';
import '../../services/session_service.dart';
import '../../localization_manager.dart';

class EmployerInProgressJobsScreen extends StatefulWidget {
  const EmployerInProgressJobsScreen({super.key});

  @override
  State<EmployerInProgressJobsScreen> createState() =>
      _EmployerInProgressJobsScreenState();
}

class _EmployerInProgressJobsScreenState
    extends State<EmployerInProgressJobsScreen> {
  List<JobPosting> _inProgressJobs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInProgressJobs();
  }

  Future<void> _loadInProgressJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = await SessionService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception(
          LocalizationManager.translate('user_session_not_found'),
        );
      }

      final jobs = await JobPostingService.getAcceptedJobsForUser(
        userId: currentUserId,
        userType: 'employer',
      );

      if (mounted) {
        setState(() {
          _inProgressJobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              '${LocalizationManager.translate('failed_to_load_active_jobs')}: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markJobAsCompleted(JobPosting job) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(LocalizationManager.translate('Confirm Completion')),
            content: Text(
              '${LocalizationManager.translate('are_you_sure')} "${job.title}" ${LocalizationManager.translate('has_been_completed_by')} ${job.assignedHelperName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(LocalizationManager.translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: Text(LocalizationManager.translate('mark_completed')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await JobPostingService.markJobAsCompleted(job.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translate('job_mark_as_completed'),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _loadInProgressJobs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationManager.translate('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationManager.translate('my_jobs')),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInProgressJobs,
                    child: Text(LocalizationManager.translate('retry')),
                  ),
                ],
              ),
            )
          : _inProgressJobs.isEmpty
          ? Center(child: Text(LocalizationManager.translate('no_active_jobs')))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _inProgressJobs.length,
              itemBuilder: (context, index) {
                final job = _inProgressJobs[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Helper: ${job.assignedHelperName}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE082),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                LocalizationManager.translate('in_progress'),
                                style: const TextStyle(
                                  color: Color(0xFFF57F17),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          job.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Color(0xFF999999),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${job.municipality}, ${job.barangay}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Color(0xFF999999),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${job.createdAt.day}/${job.createdAt.month}/${job.createdAt.year}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PHP ${job.salary}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _markJobAsCompleted(job),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                LocalizationManager.translate('mark_completed'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
