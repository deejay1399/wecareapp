import 'package:flutter/material.dart';
import '../../models/subscription_plan.dart';
import '../../models/usage_tracking.dart';
import '../../services/subscription_service.dart';
import '../../services/session_service.dart';
import '../../utils/constants/subscription_constants.dart';
import '../../widgets/subscription/subscription_plan_card.dart';
import '../../widgets/subscription/trial_status_card.dart';
import '../../localization_manager.dart';

class HelperSubscriptionScreen extends StatefulWidget {
  const HelperSubscriptionScreen({super.key});

  @override
  State<HelperSubscriptionScreen> createState() =>
      _HelperSubscriptionScreenState();
}

class _HelperSubscriptionScreenState extends State<HelperSubscriptionScreen> {
  Map<String, dynamic>? _subscriptionStatus;
  bool _isLoading = true;
  String? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final status =
          await SubscriptionService.getCurrentUserSubscriptionStatus();
      setState(() {
        _subscriptionStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _subscribeToPlan(SubscriptionPlan plan) async {
    setState(() {
      _selectedPlanId = plan.id;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      final userId = await SessionService.getCurrentUserId();
      if (userId != null) {
        print("🔵 DEBUG: Subscribing user $userId to ${plan.name}");

        await SubscriptionService.createOrUpdateSubscription(
          userId,
          'Helper',
          plan,
          true,
        );

        // CRITICAL: Show immediate feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${LocalizationManager.translate('successfully_subscribed_to')} ${plan.name}!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // CRITICAL: Update UI immediately
          setState(() {
            _subscriptionStatus = {
              'canUse': true,
              'hasSubscription': true,
              'isTrialUser': false,
            };
            _isLoading = false;
          });

          print("✔ UI updated immediately - showing active subscription");
        }

        // Wait for database to sync
        await Future.delayed(const Duration(milliseconds: 800));

        // Reload to sync with database
        await _loadSubscriptionStatus();

        print("✔ Subscription status reloaded after DB sync");
      }
    } catch (e) {
      print("❌ Subscription error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationManager.translate('subscription_failed')} $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _selectedPlanId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          LocalizationManager.translate('subscription_plans'),
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.black12,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trial Status Card
                  if (_subscriptionStatus?['isTrialUser'] == true)
                    TrialStatusCard(
                      usage: _subscriptionStatus!['usage'] as UsageTracking,
                      userType: 'Helper',
                    ),

                  // Current Subscription Status
                  if (_subscriptionStatus?['hasSubscription'] == true)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            LocalizationManager.translate(
                              'active_subscription',
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LocalizationManager.translate(
                              'you_have_unlimited_access_to_all_features',
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                  // Header
                  Text(
                    LocalizationManager.translate('choose_your_plan'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LocalizationManager.translate(
                      'unlock_unlimited_job_opportunities_and_connect_with_employers_in_your_area',
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subscription Plans
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: SubscriptionConstants.availablePlans.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final plan = SubscriptionConstants.availablePlans[index];
                      final isSelected = _selectedPlanId == plan.id;
                      final isPopular = plan.id == 'standard';
                      final hasSubscription =
                          _subscriptionStatus?['hasSubscription'] == true;
                      final currentPlanId = _subscriptionStatus?['planId'];

                      return SubscriptionPlanCard(
                        plan: plan,
                        isPopular: isPopular,
                        isLoading: isSelected,
                        isDisabled: hasSubscription && currentPlanId != plan.id,
                        onSubscribe: () => _subscribeToPlan(plan),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Features included
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizationManager.translate('whats_included'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem(
                          LocalizationManager.translate(
                            'unlimited_job_applications',
                          ),
                        ),
                        _buildFeatureItem(
                          LocalizationManager.translate(
                            'connect_with_verified_employers',
                          ),
                        ),
                        _buildFeatureItem(
                          LocalizationManager.translate(
                            'access_to_premium_job_listings',
                          ),
                        ),
                        _buildFeatureItem(
                          LocalizationManager.translate(
                            'priority_application_status',
                          ),
                        ),
                        _buildFeatureItem(
                          LocalizationManager.translate(
                            'advanced_profile_visibility',
                          ),
                        ),
                        _buildFeatureItem(
                          LocalizationManager.translate(
                            'in_app_messaging_with_employers',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
