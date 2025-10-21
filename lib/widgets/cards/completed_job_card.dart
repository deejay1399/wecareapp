import 'package:flutter/material.dart';
import '../../models/job_posting.dart';
import '../../models/rating.dart';
import '../../services/rating_service.dart';
import '../../screens/rating/rating_dialog_screen.dart';
import '../../screens/rating/user_ratings_screen.dart';
import '../rating/star_rating_display.dart';
import '../../localization_manager.dart';

class CompletedJobCard extends StatefulWidget {
  final JobPosting job;
  final String userType;
  final String userId;
  final VoidCallback? onRatingSubmitted;

  const CompletedJobCard({
    super.key,
    required this.job,
    required this.userType,
    required this.userId,
    this.onRatingSubmitted,
  });

  @override
  State<CompletedJobCard> createState() => _CompletedJobCardState();
}

class _CompletedJobCardState extends State<CompletedJobCard> {
  final _ratingService = RatingService();
  Rating? _existingRating;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    _loadExistingRating();
  }

  Future<void> _loadExistingRating() async {
    try {
      final existingRating = await _ratingService.getExistingRating(
        raterId: widget.userId,
        raterType: widget.userType,
        ratedId: widget.userType == 'helper'
            ? widget.job.employerId
            : widget.job.assignedHelperId ?? '',
        ratedType: widget.userType == 'helper' ? 'employer' : 'helper',
        jobPostingId: widget.job.id,
      );

      if (mounted) {
        setState(() {
          _existingRating = existingRating;
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

  Future<void> _openRatingDialog() async {
    if (widget.userType == 'employer' && widget.job.assignedHelperId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot rate: No helper assigned to this job'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RatingDialogScreen(
          raterId: widget.userId,
          raterType: widget.userType,
          ratedId: widget.userType == 'helper'
              ? widget.job.employerId
              : widget.job.assignedHelperId!,
          ratedType: widget.userType == 'helper' ? 'employer' : 'helper',
          ratedName: widget.userType == 'helper'
              ? 'Employer'
              : widget.job.assignedHelperName ?? 'Helper',
          jobPostingId: widget.job.id,
          title: _existingRating != null ? 'Update Rating' : 'Rate Experience',
        ),
      ),
    );

    if (result != null) {
      // Rating was submitted/updated
      await _loadExistingRating();
      widget.onRatingSubmitted?.call();
    }
  }

  void _viewRatings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserRatingsScreen(
          userId: widget.userType == 'helper'
              ? widget.job.employerId
              : widget.job.assignedHelperId ?? '',
          userType: widget.userType == 'helper' ? 'employer' : 'helper',
          userName: widget.userType == 'helper'
              ? 'Employer'
              : widget.job.assignedHelperName ?? 'Helper',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return LocalizationManager.translate('today');
    } else if (difference == 1) {
      return LocalizationManager.translate('yesterday');
    } else if (difference < 7) {
      return LocalizationManager.translate(
        'days_ago',
        params: {'count': difference.toString()},
      );
    } else if (difference < 30) {
      return LocalizationManager.translate(
        'weeks_ago',
        params: {'count': (difference / 7).floor().toString()},
      );
    } else {
      return LocalizationManager.translate(
        'months_ago',
        params: {'count': (difference / 30).floor().toString()},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.job.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completed ${_formatDate(widget.job.updatedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
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
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'COMPLETED',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Job Details
            if (widget.job.description.isNotEmpty) ...[
              Text(
                widget.job.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],

            // People involved
            Row(
              children: [
                Icon(
                  widget.userType == 'helper' ? Icons.business : Icons.person,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.userType == 'helper'
                        ? 'Employer: Unknown'
                        : 'Helper: ${widget.job.assignedHelperName ?? "Not assigned"}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Rating Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Your Rating',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_isLoadingRating) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ] else if (_existingRating != null) ...[
                    // Show existing rating
                    Row(
                      children: [
                        StarRatingDisplay(
                          rating: _existingRating!.rating.toDouble(),
                          showTotalRatings: false,
                          showRatingText: true,
                          size: 18,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _openRatingDialog,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFF8A50),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                          child: const Text(
                            'Update',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (_existingRating!.reviewText != null &&
                        _existingRating!.reviewText!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '"${_existingRating!.reviewText}"',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ] else ...[
                    // No rating yet - show rate button
                    Row(
                      children: [
                        Text(
                          'Not rated yet',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _openRatingDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8A50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Rate Now',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        widget.userType == 'employer' &&
                            widget.job.assignedHelperId != null
                        ? _viewRatings
                        : widget.userType == 'helper'
                        ? _viewRatings
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8A50),
                      side: const BorderSide(color: Color(0xFFFF8A50)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      widget.userType == 'helper'
                          ? 'View Employer Reviews'
                          : 'View Helper Reviews',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
