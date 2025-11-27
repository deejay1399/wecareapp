import 'package:flutter/material.dart';
import '../../models/subscription_plan.dart';
import '../../utils/constants/subscription_constants.dart';
import '../../screens/subscription/subscription_success_screen.dart';
import '../../localization_manager.dart';

class SubscriptionPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isPopular;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onSubscribe;

  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    this.isPopular = false,
    this.isLoading = false,
    this.isDisabled = false,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final planColor = Color(
      SubscriptionConstants.planColors[plan.id] ?? 0xFF2196F3,
    );

    void handleSubscribe(BuildContext context) {
      onSubscribe();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionSuccessScreen(plan: plan),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPopular
            ? Border.all(color: planColor, width: 2)
            : Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDisabled ? 0.02 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: Stack(
          children: [
            // Popular badge
            if (isPopular)
              Positioned(
                top: -1,
                left: 16,
                right: 16,
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: planColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            // Disabled badge
            if (isDisabled)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    LocalizationManager.translate('active'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Card content
            Padding(
              padding: EdgeInsets.fromLTRB(20, isPopular ? 40 : 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: planColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            SubscriptionConstants.planIcons[plan.id] ?? '📱',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plan.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Price and duration
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        plan.formattedPrice,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: planColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '/ ${plan.formattedDuration}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Subscribe button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isDisabled || isLoading
                          ? null
                          : () => handleSubscribe(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDisabled
                            ? Colors.grey[400]
                            : planColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              isDisabled
                                  ? LocalizationManager.translate(
                                      'already_subscribed',
                                    )
                                  : LocalizationManager.translate(
                                      'subscribe_now',
                                    ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
