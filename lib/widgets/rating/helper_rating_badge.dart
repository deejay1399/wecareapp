import 'package:flutter/material.dart';
import '../../models/rating_statistics.dart';
import 'star_rating_display.dart';

class HelperRatingBadge extends StatelessWidget {
  final RatingStatistics statistics;
  final bool isCompact;
  final bool showBackground;
  final VoidCallback? onTap;

  const HelperRatingBadge({
    super.key,
    required this.statistics,
    this.isCompact = false,
    this.showBackground = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!statistics.hasRatings) {
      return _buildNoRatingsBadge(context);
    }

    Widget badgeContent = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: showBackground
          ? BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
              border: Border.all(color: _getBorderColor(), width: 1),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: isCompact ? 14 : 16, color: _getStarColor()),
          SizedBox(width: isCompact ? 4 : 6),
          Text(
            statistics.formattedAverageRating,
            style: TextStyle(
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: _getTextColor(),
            ),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 4),
            Text(
              '(${statistics.totalRatings})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: badgeContent);
    }

    return badgeContent;
  }

  Widget _buildNoRatingsBadge(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: showBackground
            ? BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              'No ratings',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: showBackground
          ? BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 6),
          Text(
            'New helper',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    final rating = statistics.averageRating;
    if (rating >= 4.5) return const Color(0xFFF0FDF4); // Green tint
    if (rating >= 4.0) return const Color(0xFFFFFBEB); // Yellow tint
    if (rating >= 3.0) return const Color(0xFFFEF3C7); // Orange tint
    return const Color(0xFFFEF2F2); // Red tint
  }

  Color _getBorderColor() {
    final rating = statistics.averageRating;
    if (rating >= 4.5) return const Color(0xFFBBF7D0); // Green border
    if (rating >= 4.0) return const Color(0xFFFEF3C7); // Yellow border
    if (rating >= 3.0) return const Color(0xFFFED7AA); // Orange border
    return const Color(0xFFFECDD3); // Red border
  }

  Color _getStarColor() {
    final rating = statistics.averageRating;
    if (rating >= 4.5) return const Color(0xFF10B981); // Green
    if (rating >= 4.0) return const Color(0xFFFFB800); // Yellow
    if (rating >= 3.0) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Red
  }

  Color _getTextColor() {
    final rating = statistics.averageRating;
    if (rating >= 4.5) return const Color(0xFF065F46); // Dark green
    if (rating >= 4.0) return const Color(0xFF92400E); // Dark yellow
    if (rating >= 3.0) return const Color(0xFF9A3412); // Dark orange
    return const Color(0xFF991B1B); // Dark red
  }
}

// Small compact version for cards
class SmallHelperRatingBadge extends StatelessWidget {
  final RatingStatistics statistics;
  final VoidCallback? onTap;

  const SmallHelperRatingBadge({
    super.key,
    required this.statistics,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HelperRatingBadge(
      statistics: statistics,
      isCompact: true,
      showBackground: true,
      onTap: onTap,
    );
  }
}

// Enhanced rating display with description
class EnhancedHelperRating extends StatelessWidget {
  final RatingStatistics statistics;
  final bool showDescription;
  final VoidCallback? onTap;

  const EnhancedHelperRating({
    super.key,
    required this.statistics,
    this.showDescription = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!statistics.hasRatings) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HelperRatingBadge(statistics: statistics, onTap: onTap),
          if (showDescription) ...[
            const SizedBox(height: 4),
            Text(
              'No reviews yet - be the first to rate!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HelperRatingBadge(statistics: statistics, onTap: onTap),
        if (showDescription) ...[
          const SizedBox(height: 4),
          Text(
            StarRatingDisplay.getRatingDescription(statistics.averageRating),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
