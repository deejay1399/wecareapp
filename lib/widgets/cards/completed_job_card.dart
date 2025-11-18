import 'package:flutter/material.dart';
import '../../models/job_posting.dart';
import '../../models/rating.dart';
import '../../services/rating_service.dart';
import '../../services/employer_service.dart';
import '../../services/helper_service.dart';
import '../../screens/rating/rating_dialog_screen.dart';
import '../../screens/rating/user_ratings_screen.dart';
import '../rating/star_rating_display.dart';
import '../../localization_manager.dart';

class CompletedJobCard extends StatefulWidget {
  final JobPosting job;
  final String userType; // 'employer' or 'helper'
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

  String? _displayName;
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadExistingRating();
    _loadDisplayName(); // Load employer/helper name dynamically
  }

  Future<void> _loadDisplayName() async {
    try {
      if (widget.userType == 'helper') {
        // Show Employer name
        if (widget.job.employer != null) {
          _displayName = widget.job.employer!.fullName.isNotEmpty
              ? widget.job.employer!.fullName
              : 'Employer';
        } else if (widget.job.employerId.isNotEmpty) {
          final employer = await EmployerService().getEmployerById(
            widget.job.employerId,
          );
          _displayName = employer?.fullName.isNotEmpty == true
              ? employer!.fullName
              : 'Employer';
        } else {
          _displayName = 'Employer';
        }
      } else {
        // Show Helper name
        if (widget.job.assignedHelperName != null &&
            widget.job.assignedHelperName!.isNotEmpty) {
          _displayName = widget.job.assignedHelperName;
        } else if (widget.job.assignedHelper != null) {
          _displayName = widget.job.assignedHelper!.fullName.isNotEmpty
              ? widget.job.assignedHelper!.fullName
              : 'Helper';
        } else if (widget.job.assignedHelperId != null &&
            widget.job.assignedHelperId!.isNotEmpty) {
          final helper = await HelperService().getHelperById(
            widget.job.assignedHelperId!,
          );
          _displayName = helper?.fullName.isNotEmpty == true
              ? helper!.fullName
              : 'Helper';
        } else {
          _displayName = 'Not assigned';
        }
      }
    } catch (e) {
      _displayName = 'Unknown';
    }

    if (mounted) {
      setState(() => _isLoadingName = false);
    }
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
    String? ratedId;
    if (widget.userType == 'helper') {
      ratedId = widget.job.employerId;
    } else {
      ratedId =
          (widget.job.assignedHelperId != null &&
              widget.job.assignedHelperId!.isNotEmpty)
          ? widget.job.assignedHelperId
          : widget.job.assignedHelper?.id;
    }

    if (ratedId == null || ratedId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot rate: No helper assigned to this job\nassignedHelperId=${widget.job.assignedHelperId ?? 'null'} helper.id=${widget.job.assignedHelper?.id ?? 'null'}',
          ),
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
          ratedId: ratedId!,
          ratedType: widget.userType == 'helper' ? 'employer' : 'helper',
          ratedName: widget.userType == 'helper'
              ? _displayName ?? 'Employer'
              : _displayName ?? 'Helper',
          jobPostingId: widget.job.id,
          title: _existingRating != null ? 'Update Rating' : 'Rate Experience',
        ),
      ),
    );

    if (result != null) {
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
          userName: _displayName ?? 'Unknown',
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
                      // ✅ Title wraps text
                      Text(
                        widget.job.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        softWrap: true,
                        overflow: TextOverflow.visible,
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

            // ✅ Job Description - wrap text instead of ellipsis
            if (widget.job.description.isNotEmpty) ...[
              Text(
                widget.job.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: 12),
            ],

            // Employer / Helper info
            Row(
              children: [
                Icon(
                  widget.userType == 'helper' ? Icons.business : Icons.person,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _isLoadingName
                      ? const Text("Loading...")
                      : Text(
                          widget.userType == 'helper'
                              ? 'Employer: ${_displayName ?? "Unknown"}'
                              : 'Helper: ${_displayName ?? "Not assigned"}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
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
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ] else ...[
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

            // View Reviews Button
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _viewRatings,
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
