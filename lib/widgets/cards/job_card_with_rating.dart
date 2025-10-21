import 'package:flutter/material.dart';
import '../../models/job_posting.dart';
import '../../models/rating_statistics.dart';
import '../../services/rating_service.dart';
import '../../utils/constants/payment_frequency_constants.dart';
import '../rating/star_rating_display.dart';
import '../../localization_manager.dart';

class JobCardWithRating extends StatefulWidget {
  final JobPosting job;
  final VoidCallback? onTap;
  final bool hasApplied;
  final bool showEmployerRating;
  final bool isSaved;
  final Function(bool)? onSaveToggle;

  const JobCardWithRating({
    super.key,
    required this.job,
    this.onTap,
    this.hasApplied = false,
    this.showEmployerRating = true,
    this.isSaved = false,
    this.onSaveToggle,
  });

  @override
  State<JobCardWithRating> createState() => _JobCardWithRatingState();
}

class _JobCardWithRatingState extends State<JobCardWithRating> {
  final _ratingService = RatingService();
  RatingStatistics? _employerRatingStats;

  @override
  void initState() {
    super.initState();
    if (widget.showEmployerRating) {
      _loadEmployerRatingStats();
    }
    print("print(widget.job.employer?.firstName);");
    print(widget.job.employer?.firstName);
  }

  Future<void> _loadEmployerRatingStats() async {
    try {
      final stats = await _ratingService.getUserRatingStatistics(
        widget.job.employerId,
        'employer',
      );

      if (mounted) {
        setState(() {
          _employerRatingStats = stats;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'today';
    if (difference == 1) return 'yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).floor()} weeks ago';
    return '${(difference / 30).floor()} months ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: const Color(0xFFFF8A50).withValues(alpha: 0.1),
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
                // Title, salary, and save button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.job.employer?.fullName ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      '₱${widget.job.salary.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    if (widget.onSaveToggle != null) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          widget.onSaveToggle!(!widget.isSaved);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.isSaved
                                ? const Color(0xFFFF8A50).withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 20,
                            color: widget.isSaved
                                ? const Color(0xFFFF8A50)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Age: ${widget.job.employer?.age ?? 'N/A'}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Payment frequency and location
                Row(
                  children: [
                    Text(
                      PaymentFrequencyConstants.frequencyLabels[widget
                              .job
                              .paymentFrequency] ??
                          widget.job.paymentFrequency,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.job.barangay,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // title
                Text(
                  "Job title: ${widget.job.title}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                Text(
                  "Job description: ${widget.job.description}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Employer rating (if enabled)
                if (widget.showEmployerRating) ...[
                  if (_employerRatingStats != null &&
                      _employerRatingStats!.hasRatings) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.business,
                          size: 16,
                          color: Color(0xFF1565C0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Employer Rating:',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StarRatingDisplay(
                          rating: _employerRatingStats!.averageRating,
                          totalRatings: _employerRatingStats!.totalRatings,
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else if (_employerRatingStats != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.business,
                          size: 16,
                          color: Color(0xFF1565C0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Employer Rating:',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          LocalizationManager.translate('no_ratings_yet'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ],

                // Required skills
                if (widget.job.requiredSkills.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.job.requiredSkills.take(3).map((skill) {
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
                  const SizedBox(height: 12),
                ],

                // Posted date and apply button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Posted ${_formatDate(widget.job.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    widget.hasApplied
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Applied',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: widget.onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8A50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
