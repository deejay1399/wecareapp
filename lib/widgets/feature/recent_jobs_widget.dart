import 'package:flutter/material.dart';
import '../../models/job_posting.dart';
import '../../models/helper.dart';
import '../cards/job_card_with_rating.dart';

class RecentJobsWidget extends StatelessWidget {
  final Helper? currentHelper;
  final List<JobPosting> jobPostings;
  final Function(JobPosting) onJobTap;
  final Set<String> appliedJobIds;
  final Set<String> savedJobIds;
  final Function(JobPosting, bool) onSaveToggle;

  const RecentJobsWidget({
    super.key,
    required this.currentHelper,
    required this.jobPostings,
    required this.onJobTap,
    required this.appliedJobIds,
    required this.savedJobIds,
    required this.onSaveToggle,
  });

  List<JobPosting> _getTodaysJobs(List<JobPosting> jobs) {
    final today = DateTime.now();
    return jobs.where((job) {
      final createdAt = job.createdAt;
      return createdAt.year == today.year &&
          createdAt.month == today.month &&
          createdAt.day == today.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final todaysJobs = _getTodaysJobs(jobPostings);
    final otherRecentJobs = jobPostings
        .where((job) => !todaysJobs.any((todayJob) => todayJob.id == job.id))
        .toList();

    if (jobPostings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {}, // Parent handles refresh
      color: const Color(0xFFFF8A50),
      child: ListView(
        children: [
          _buildTodaysJobsSection(todaysJobs),
          _buildRecentJobsSection(otherRecentJobs),
          const SizedBox(height: 24), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildTodaysJobsSection(List<JobPosting> todaysJobs) {
    if (todaysJobs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.today,
                  size: 16,
                  color: Color(0xFFFF8A50),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Posted Today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF8A50).withOpacity(0.2),
                  ),
                ),
                child: Text(
                  '${todaysJobs.length} new',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF8A50),
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: todaysJobs.length,
          itemBuilder: (context, index) {
            final job = todaysJobs[index];
            print("job");
            print(job);
            return JobCardWithRating(
              job: job,
              hasApplied: appliedJobIds.contains(job.id),
              isSaved: savedJobIds.contains(job.id),
              onTap: () => onJobTap(job),
              onSaveToggle: (isSaved) => onSaveToggle(job, isSaved),
            );
          },
        ),
        if (jobPostings.length > todaysJobs.length) ...[
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: Color(0xFFE5E7EB)),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildRecentJobsSection(List<JobPosting> recentJobs) {
    if (recentJobs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Jobs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: recentJobs.length,
          itemBuilder: (context, index) {
            final job = recentJobs[index];
            return JobCardWithRating(
              job: job,
              hasApplied: appliedJobIds.contains(job.id),
              isSaved: savedJobIds.contains(job.id),
              onTap: () => onJobTap(job),
              onSaveToggle: (isSaved) => onSaveToggle(job, isSaved),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFF8A50).withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        size: 60,
                        color: Color(0xFFFF8A50),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'No Recent Jobs',
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
                        'New job opportunities will appear here when employers post them. Check back regularly for fresh opportunities!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
