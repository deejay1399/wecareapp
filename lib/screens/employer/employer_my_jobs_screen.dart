import 'package:flutter/material.dart';
import '../../models/job_posting.dart';
import '../../services/job_posting_service.dart';
import '../../services/application_service.dart';
import '../../services/session_service.dart';
import '../../widgets/cards/job_posting_card.dart';
import 'post_job_screen.dart';
import 'job_details_screen.dart';
import "../../localization_manager.dart";

class EmployerMyJobsScreen extends StatefulWidget {
  const EmployerMyJobsScreen({super.key});

  @override
  State<EmployerMyJobsScreen> createState() => _EmployerMyJobsScreenState();
}

class _EmployerMyJobsScreenState extends State<EmployerMyJobsScreen> {
  List<JobPosting> _jobPostings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadJobPostings();
  }

  Future<void> _loadJobPostings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current employer
      final employer = await SessionService.getCurrentEmployer();
      if (employer != null) {
        // Load job postings for this employer (expired jobs are automatically filtered out)
        final jobPostings = await JobPostingService.getJobPostingsByEmployer(
          employer.id,
        );

        // Load application counts for each job posting
        for (int i = 0; i < jobPostings.length; i++) {
          try {
            final count = await ApplicationService.getApplicationCount(
              jobPostings[i].id,
            );
            jobPostings[i] = JobPosting(
              id: jobPostings[i].id,
              employerId: jobPostings[i].employerId,
              title: jobPostings[i].title,
              description: jobPostings[i].description,
              municipality: jobPostings[i].municipality,
              barangay: jobPostings[i].barangay,
              salary: jobPostings[i].salary,
              paymentFrequency: jobPostings[i].paymentFrequency,
              requiredSkills: jobPostings[i].requiredSkills,
              status: jobPostings[i].status,
              createdAt: jobPostings[i].createdAt,
              updatedAt: jobPostings[i].updatedAt,
              applicationsCount: count,
            );
          } catch (e) {
            // If application count fails, keep original job posting
          }
        }

        if (mounted) {
          setState(() {
            _jobPostings = jobPostings;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = LocalizationManager.translate(
            'failed_to_load_employer_information',
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              '${LocalizationManager.translate('failed_to_load_job_postings')}: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onPostJob() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostJobScreen()),
    );

    // If job was posted successfully, refresh the job list
    if (result == true) {
      _loadJobPostings();
    }
  }

  void _onJobTap(JobPosting job) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailsScreen(jobPosting: job),
      ),
    );

    // Handle different results from job details screen
    if (result == 'deleted' && mounted) {
      // Job was deleted, refresh the list
      _loadJobPostings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationManager.translate('job_posting_deleted_successfully'),
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else if (result != null) {
      // Job was updated, refresh the list
      _loadJobPostings();
    }
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
                Icons.post_add,
                size: 60,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              LocalizationManager.translate('no_job_postings_yet'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                LocalizationManager.translate(
                  'start_finding_the_perfect_helpers_by_posting_your_first_job',
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            // Post Job Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onPostJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF1565C0).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Color(0xFF1565C0),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      LocalizationManager.translate('post_your_first_job'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Benefits list
            Column(
              children: [
                _buildBenefitItem(
                  Icons.search,
                  LocalizationManager.translate(
                    'find_qualified_helpers_quickly',
                  ),
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  Icons.schedule,
                  LocalizationManager.translate('set_your_own_schedule'),
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  Icons.verified_user,
                  LocalizationManager.translate('all_helpers_are_verified'),
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

  Widget _buildContent() {
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
              Text(
                LocalizationManager.translate('error_loading_jobs'),
                style: const TextStyle(
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
                onPressed: _loadJobPostings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(LocalizationManager.translate('retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_jobPostings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadJobPostings,
      color: const Color(0xFF1565C0),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _jobPostings.length,
        itemBuilder: (context, index) {
          return JobPostingCard(
            jobPosting: _jobPostings[index],
            onTap: () => _onJobTap(_jobPostings[index]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header with Post Job Button
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      LocalizationManager.translate('my_jobs'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                  if (_jobPostings.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: _onPostJob,
                        icon: const Icon(
                          Icons.add,
                          color: Color(0xFF1565C0),
                          size: 24,
                        ),
                        tooltip: LocalizationManager.translate('post_new_job'),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }
}
