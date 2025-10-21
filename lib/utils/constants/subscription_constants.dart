import '../../models/subscription_plan.dart';
import '../../localization_manager.dart';

class SubscriptionConstants {
  // Trial limits
  static const int employerTrialLimit = 5;
  static const int helperTrialLimit = 8;

  // Subscription plans
  static List<SubscriptionPlan> get availablePlans => [
    SubscriptionPlan(
      id: 'starter',
      name: LocalizationManager.translate('starter_plan'),
      description: LocalizationManager.translate('starter_plan_description'),
      price: 50.0,
      durationInDays: 28, // 4 weeks
      currency: 'PHP',
    ),
    SubscriptionPlan(
      id: 'standard',
      name: LocalizationManager.translate('standard_plan'),
      description: LocalizationManager.translate('standard_plan_description'),
      price: 100.0,
      durationInDays: 90, // 3 months
      currency: 'PHP',
    ),
    SubscriptionPlan(
      id: 'premium',
      name: LocalizationManager.translate('premium_plan'),
      description: LocalizationManager.translate('premium_plan_description'),
      price: 199.0,
      durationInDays: 180, // 6 months
      currency: 'PHP',
    ),
  ];

  // Helper methods
  static int getTrialLimitForUserType(String userType) {
    switch (userType.toLowerCase()) {
      case 'employer':
        return employerTrialLimit;
      case 'helper':
        return helperTrialLimit;
      default:
        return 0;
    }
  }

  static SubscriptionPlan? getPlanById(String planId) {
    try {
      return availablePlans.firstWhere((plan) => plan.id == planId);
    } catch (e) {
      return null;
    }
  }

  static List<SubscriptionPlan> getActivePlans() {
    return availablePlans.where((plan) => plan.isActive).toList();
  }

  // Plan colors for UI
  static const Map<String, int> planColors = {
    'starter': 0xFF4CAF50, // Green
    'standard': 0xFF2196F3, // Blue
    'premium': 0xFF9C27B0, // Purple
  };

  // Plan icons
  static const Map<String, String> planIcons = {
    'starter': '🌱',
    'standard': '⭐',
    'premium': '👑',
  };
}
