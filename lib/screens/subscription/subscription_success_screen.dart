import 'package:flutter/material.dart';
import '../../models/subscription_plan.dart';
import '../../utils/constants/subscription_constants.dart';
import '../../services/subscription_service.dart';

class SubscriptionSuccessScreen extends StatelessWidget {
  final SubscriptionPlan plan;

  const SubscriptionSuccessScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final planColor = Color(
      SubscriptionConstants.planColors[plan.id] ?? 0xFF2196F3,
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: planColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Subscription Successful'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: planColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: planColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    SubscriptionConstants.planIcons[plan.id] ?? '🎉',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Steps to follow:',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: planColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Send the ${plan.currency} ${plan.price} to this number using gcash: 09518710753',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              Text(
                '2. Please wait for confirmation of your ${plan.name}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              // const SizedBox(height: 16),
              // Text(
              //   '2. Enjoy your benefits for ${plan.formattedDuration}!',
              //   style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              // ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    await SubscriptionService.saveCurrentUserSubscriptionToSupabase(
                      plan,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Successfully subscribed to ${plan.name}!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: planColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Subscribe to this plan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
