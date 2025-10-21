import 'package:flutter/material.dart';
import '../../models/rating_statistics.dart';
import 'star_rating_display.dart';
import '../../localization_manager.dart';

class RatingSummary extends StatelessWidget {
  final RatingStatistics statistics;
  final bool showDistribution;

  const RatingSummary({
    super.key,
    required this.statistics,
    this.showDistribution = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!statistics.hasRatings) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            LocalizationManager.translate('no_ratings_yet'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to leave a rating!',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        statistics.formattedAverageRating,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'out of 5',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StarRatingDisplay(
                    rating: statistics.averageRating,
                    showRatingText: false,
                    showTotalRatings: false,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${statistics.totalRatings} rating${statistics.totalRatings != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (showDistribution && statistics.totalRatings > 0) 
              _buildRatingDistribution(context),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingDistribution(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int star = 5; star >= 1; star--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$star',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.star,
                  size: 14,
                  color: Colors.amber[600],
                ),
                const SizedBox(width: 8),
                Container(
                  width: 80,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _getStarPercentage(star),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber[600],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  child: Text(
                    '${statistics.ratingDistribution[star] ?? 0}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  double _getStarPercentage(int star) {
    if (statistics.totalRatings == 0) return 0.0;
    final count = statistics.ratingDistribution[star] ?? 0;
    return count / statistics.totalRatings;
  }
}
