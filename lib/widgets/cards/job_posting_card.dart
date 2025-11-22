import 'package:flutter/material.dart';
import '../../models/job_posting.dart';
import '../../models/rating_statistics.dart';
import '../../services/rating_service.dart';
import '../../localization_manager.dart';
import '../rating/star_rating_display.dart';

class JobPostingCard extends StatefulWidget {
  final JobPosting jobPosting;
  final VoidCallback? onTap;

  const JobPostingCard({super.key, required this.jobPosting, this.onTap});

  @override
  State<JobPostingCard> createState() => _JobPostingCardState();
}

class _JobPostingCardState extends State<JobPostingCard> {
  final _ratingService = RatingService();
  RatingStatistics? _employerRatingStats;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    _loadEmployerRatingStats();
  }

  Future<void> _loadEmployerRatingStats() async {
    try {
      final stats = await _ratingService.getUserRatingStatistics(
        widget.jobPosting.employerId,
        'employer',
      );

      if (mounted) {
        setState(() {
          _employerRatingStats = stats;
          _isLoadingRating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRating = false;
        });
      }
    }
  }

  Color _getStatusColor() {
    switch (widget.jobPosting.status) {
      case 'active':
        return const Color(0xFF4CAF50);
      case 'paused':
        return const Color(0xFFFF9800);
      case 'closed':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return LocalizationManager.translate('today');
    if (difference == 1) return LocalizationManager.translate('yesterday');
    return '$difference ${LocalizationManager.translate('days_ago')}';
  }

  String _formatSalary() {
    return '₱${widget.jobPosting.salary.toStringAsFixed(0)}/${widget.jobPosting.salaryPeriod}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
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
                // Header with title and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.jobPosting.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
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
                        widget.jobPosting.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  widget.jobPosting.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Location and salary row
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.jobPosting.location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatSalary(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Employer Rating
                if (!_isLoadingRating) ...[
                  if (_employerRatingStats != null &&
                      _employerRatingStats!.hasRatings) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A50).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF8A50).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.business,
                            size: 16,
                            color: Color(0xFFFF8A50),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocalizationManager.translate(
                                    'employer_rating',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                StarRatingDisplay(
                                  rating: _employerRatingStats!.averageRating,
                                  totalRatings:
                                      _employerRatingStats!.totalRatings,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.business,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              LocalizationManager.translate('no_ratings_yet'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],

                const SizedBox(height: 16),

                // Bottom row with applications and date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.jobPosting.applicationsCount} ${LocalizationManager.translate('applications')}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatDate(widget.jobPosting.postedDate),
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
