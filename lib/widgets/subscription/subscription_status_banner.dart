import 'package:flutter/material.dart';
import '../../models/usage_tracking.dart';
import '../../models/subscription.dart';
import '../../localization_manager.dart';

class SubscriptionStatusBanner extends StatelessWidget {
  final Map<String, dynamic> subscriptionStatus;
  final VoidCallback onTap;

  const SubscriptionStatusBanner({
    super.key,
    required this.subscriptionStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (subscriptionStatus['hasSubscription'] == true) {
      return _buildSubscriptionBanner(context);
    } else if (subscriptionStatus['isTrialUser'] == true) {
      return _buildTrialBanner(context);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildSubscriptionBanner(BuildContext context) {
    final subscription = subscriptionStatus['subscription'] as Subscription;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationManager.translate('premium_user'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subscription.expiryDate != null
                            ? '${LocalizationManager.translate('expires')} ${_formatDate(subscription.expiryDate!)}'
                            : LocalizationManager.translate(
                                'active_subscription',
                              ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.green[600], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrialBanner(BuildContext context) {
    final usage = subscriptionStatus['usage'] as UsageTracking;
    final isNearLimit = usage.remainingTrialUses <= 2;
    final isAtLimit = usage.hasExceededTrial;

    Color statusColor;
    Color backgroundColor;
    IconData statusIcon;
    String statusText;
    String subText;

    if (isAtLimit) {
      statusColor = Colors.red[600]!;
      backgroundColor = Colors.red[50]!;
      statusIcon = Icons.warning;
      statusText = LocalizationManager.translate('trial_ended');
      subText = LocalizationManager.translate('subscribe_to_continue');
    } else if (isNearLimit) {
      statusColor = Colors.orange[600]!;
      backgroundColor = Colors.orange[50]!;
      statusIcon = Icons.access_time;
      statusText =
          '${usage.remainingTrialUses} ${LocalizationManager.translate('uses_left')}';
      subText = LocalizationManager.translate('subscribe_for_unlimited_access');
    } else {
      statusColor = Colors.blue[600]!;
      backgroundColor = Colors.blue[50]!;
      statusIcon = Icons.rocket_launch;
      statusText =
          '${usage.remainingTrialUses} ${LocalizationManager.translate('free_uses_left')}';
      subText = LocalizationManager.translate('subscription_recommendation');
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subText,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                // Progress indicator for trial
                if (!isAtLimit) ...[
                  const SizedBox(width: 12),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          value: usage.trialUsagePercentage,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            statusColor,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                      Text(
                        '${usage.usageCount}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: statusColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).round();
      return '${LocalizationManager.translate('in')} $months ${LocalizationManager.translate('months')}${months > 1 ? 's' : ''}';
    } else if (difference.inDays > 0) {
      return '${LocalizationManager.translate('in')} ${difference.inDays} ${LocalizationManager.translate('days')}${difference.inDays > 1 ? 's' : ''}';
    } else {
      return LocalizationManager.translate('today');
    }
  }
}
