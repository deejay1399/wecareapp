import 'package:flutter/material.dart';
import '../../models/job_posting.dart';
import '../../services/job_posting_service.dart';
import '../../services/session_service.dart';
import '../../services/subscription_service.dart';
import '../rating/rating_dialog_screen.dart';
import '../../localization_manager.dart';

class HelperActiveJobsScreen extends StatefulWidget {
  const HelperActiveJobsScreen({super.key});

  @override
  State<HelperActiveJobsScreen> createState() => _HelperActiveJobsScreenState();
}

class _HelperActiveJobsScreenState extends State<HelperActiveJobsScreen> {
  List<JobPosting> _activeJobs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActiveJobs();
  }

  Future<void> _loadActiveJobs() async {
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

      final jobs = await JobPostingService.getInProgressJobsForHelper(
        currentUserId,
      );

      if (mounted) {
        setState(() {
          _activeJobs = jobs;
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
            title: Text(LocalizationManager.translate('mark_job_completed')),
            content: Text(
              LocalizationManager.translateWithArgs('confirm_job_completed', {
                'title': job.title,
              }),
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

      // Track completed jobs and award free uses when threshold reached
      final currentUserId = await SessionService.getCurrentUserId();
      final currentUserType = await SessionService.getCurrentUserType();
      if (currentUserId != null && currentUserType != null) {
        final added = await SubscriptionService.addBonusTrialUses(
          currentUserId,
          currentUserType,
          currentUserType == 'Helper' ? 'helpers' : 'employers',
        );

        if (added > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                // simple user-facing message; add localization key if desired
                '${added.toString()} free uses added! ${LocalizationManager.translate('enjoy_extra_uses')}',
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translate('job_completed_success'),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );

        // Show rating dialog
        _showRatingDialog(job);

        // Refresh the list
        _loadActiveJobs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translateWithArgs('job_completed_failed', {
                'error': e.toString(),
              }),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRatingDialog(JobPosting job) async {
    final currentUserId = await SessionService.getCurrentUserId();
    if (currentUserId == null) return;

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RatingDialogScreen(
            raterId: currentUserId,
            raterType: 'helper',
            ratedId: job.employerId,
            ratedType: 'employer',
            ratedName: LocalizationManager.translate('employer'),
            jobPostingId: job.id,
            title: LocalizationManager.translate('rate_the_employer'),
          ),
        ),
      );
    }
  }

  Widget _buildJobCard(JobPosting job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: const Color(0xFFFF8A50).withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 18,
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
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      job.statusDisplayText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Job Description
              Text(
                job.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              // Job Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizationManager.translate('salary'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          '₱${job.salary.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizationManager.translate('location'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          job.barangay,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Skills Required
              if (job.requiredSkills.isNotEmpty) ...[
                Text(
                  LocalizationManager.translate('skills'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: job.requiredSkills.take(3).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF8A50),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _markJobAsCompleted(job),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    LocalizationManager.translate('mark_as_completed'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.work_outline,
                size: 60,
                color: Color(0xFFFF8A50),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              LocalizationManager.translate('no_active_jobs'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              LocalizationManager.translate('no_active_jobs_description'),
              style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
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
        title: Text(
          LocalizationManager.translate('active_jobs'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF8A50),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8A50)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadActiveJobs,
        color: const Color(0xFFFF8A50),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF8A50)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadActiveJobs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A50),
                  foregroundColor: Colors.white,
                ),
                child: Text(LocalizationManager.translate('retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_activeJobs.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _activeJobs.length,
      itemBuilder: (context, index) {
        return _buildJobCard(_activeJobs[index]);
      },
    );
  }
}
