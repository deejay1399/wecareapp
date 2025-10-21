import 'package:flutter/material.dart';
import '../../models/helper_service_posting.dart';
import '../../models/rating_statistics.dart';
import '../../services/rating_service.dart';
import '../rating/star_rating_display.dart';
import '../../localization_manager.dart';

class HelperServicePostingCard extends StatefulWidget {
  final HelperServicePosting servicePosting;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final bool showRating;

  const HelperServicePostingCard({
    super.key,
    required this.servicePosting,
    this.onTap,
    this.onEdit,
    this.showRating = true,
  });

  @override
  State<HelperServicePostingCard> createState() => _HelperServicePostingCardState();
}

class _HelperServicePostingCardState extends State<HelperServicePostingCard> {
  final _ratingService = RatingService();
  RatingStatistics? _ratingStats;

  @override
  void initState() {
    super.initState();
    if (widget.showRating) {
      _loadRatingStats();
    }
  }

  Future<void> _loadRatingStats() async {
    try {
      final stats = await _ratingService.getUserRatingStatistics(
        widget.servicePosting.helperId,
        'helper',
      );
      
      if (mounted) {
        setState(() {
          _ratingStats = stats;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Widget _buildSkillsChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.servicePosting.skills.take(3).map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: widget.servicePosting.statusColor.withValues(alpha: 0.1),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.servicePosting.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.servicePosting.statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.servicePosting.statusColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.servicePosting.statusDisplayText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.servicePosting.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  widget.servicePosting.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Helper rating (if enabled)
                if (widget.showRating) ...[
                  if (_ratingStats != null && _ratingStats!.hasRatings) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 16,
                          color: Color(0xFFFF8A50),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.servicePosting.helperName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StarRatingDisplay(
                          rating: _ratingStats!.averageRating,
                          totalRatings: _ratingStats!.totalRatings,
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else if (_ratingStats != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 16,
                          color: Color(0xFFFF8A50),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.servicePosting.helperName,
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

                // Skills and Rate
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocalizationManager.translate('expertise'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildSkillsChips(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          LocalizationManager.translate('rates'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.servicePosting.formatRate(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF8A50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Service areas and availability
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
                        widget.servicePosting.serviceAreasText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.servicePosting.availability,
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

                // Bottom row with stats and actions
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.servicePosting.viewsCount} views',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.message_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.servicePosting.contactsCount} contacts',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.servicePosting.formatCreatedDate(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onEdit != null)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: widget.onEdit,
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFFFF8A50),
                            size: 20,
                          ),
                          tooltip: 'Edit Service',
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
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
