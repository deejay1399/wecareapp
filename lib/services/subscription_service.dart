import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import '../models/subscription_plan.dart';
import '../models/usage_tracking.dart';
import '../utils/constants/subscription_constants.dart';
import 'session_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

class SubscriptionService {
  // Save subscription to Supabase
  static Future<void> saveSubscriptionToSupabase({
    required String userId,
    required DateTime expiryDate,
    required String planName,
    required num planAmount,
    required bool status,
  }) async {
    final createdAt = DateTime.now().toUtc();
    await SupabaseService.client.from('subscriptions').insert({
      'user_id': userId,
      'expiry_date': expiryDate.toIso8601String(),
      'plan_name': planName,
      'amount': planAmount,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    });
  }

  static Future<void> saveCurrentUserSubscriptionToSupabase(
    SubscriptionPlan plan,
  ) async {
    final userId = await SessionService.getCurrentUserId();
    if (userId == null) return;
    final expiryDate = DateTime.now().add(Duration(days: plan.durationInDays));
    await saveSubscriptionToSupabase(
      userId: userId,
      expiryDate: expiryDate,
      planName: plan.name,
      planAmount: plan.price,
      status: true,
    );
  }

  static const String _keyUsageTracking = 'usage_tracking_';
  static const String _keyCompletedJobs = 'completed_jobs_';
  static const String _keySubscription = 'subscription_';

  // Get user usage tracking
  static Future<UsageTracking?> getUserUsageTracking(
    String userId,
    String userType,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyUsageTracking$userId';
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> data = {
          'id': userId,
          'user_id': userId,
          'user_type': userType,
          'usage_count': prefs.getInt('${key}_count') ?? 0,
          // Read persisted trial limit if present, otherwise fallback to default
          'trial_limit':
              prefs.getInt('${key}_limit') ??
              SubscriptionConstants.getTrialLimitForUserType(userType),
          'last_used_at':
              prefs.getString('${key}_last_used') ??
              DateTime.now().toIso8601String(),
          'created_at':
              prefs.getString('${key}_created') ??
              DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        return UsageTracking.fromMap(data);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Initialize usage tracking for new user
  static Future<UsageTracking> initializeUsageTracking(
    String userId,
    String userType,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyUsageTracking$userId';
    final now = DateTime.now();

    final tracking = UsageTracking(
      id: userId,
      userId: userId,
      userType: userType,
      usageCount: 0,
      trialLimit: SubscriptionConstants.getTrialLimitForUserType(userType),
      lastUsedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    await prefs.setInt('${key}_count', tracking.usageCount);
    // Persist the initial trial limit so it can be adjusted later
    await prefs.setInt('${key}_limit', tracking.trialLimit);
    await prefs.setString(
      '${key}_last_used',
      tracking.lastUsedAt.toIso8601String(),
    );
    await prefs.setString(
      '${key}_created',
      tracking.createdAt.toIso8601String(),
    );

    return tracking;
  }

  // Increment usage count
  static Future<UsageTracking> incrementUsage(
    String userId,
    String userType,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyUsageTracking$userId';

    final currentCount = prefs.getInt('${key}_count') ?? 0;
    final newCount = currentCount + 1;
    final now = DateTime.now();

    await prefs.setInt('${key}_count', newCount);
    await prefs.setString('${key}_last_used', now.toIso8601String());

    // Use persisted trial limit if available
    final persistedLimit =
        prefs.getInt('${key}_limit') ??
        SubscriptionConstants.getTrialLimitForUserType(userType);

    final tracking = UsageTracking(
      id: userId,
      userId: userId,
      userType: userType,
      usageCount: newCount,
      trialLimit: persistedLimit,
      lastUsedAt: now,
      createdAt: DateTime.parse(
        prefs.getString('${key}_created') ?? now.toIso8601String(),
      ),
      updatedAt: now,
    );

    return tracking;
  }

  // Increment completed jobs counter for a user and add free uses when threshold reached
  // Returns number of free uses added (0 or >0)
  static Future<int> incrementCompletedJobsAndMaybeAddFreeUses(
    String userId,
    String userType, {
    int threshold = 3,
    int bonusUses = 3,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final completedKey = '$_keyCompletedJobs$userId';

    final current = prefs.getInt('${completedKey}_count') ?? 0;
    final newCount = current + 1;
    await prefs.setInt('${completedKey}_count', newCount);

    if (newCount % threshold == 0) {
      // add bonusUses to persisted trial limit
      final usageKey = '$_keyUsageTracking$userId';
      final currentLimit =
          prefs.getInt('${usageKey}_limit') ??
          SubscriptionConstants.getTrialLimitForUserType(userType);
      final newLimit = currentLimit + bonusUses;
      await prefs.setInt('${usageKey}_limit', newLimit);

      // Create notification for the user
      try {
        await NotificationService.createNotification(
          recipientId: userId,
          title: 'Free Uses Awarded! 🎉',
          body:
              'Congratulations! You have earned $bonusUses free uses after completing $newCount jobs.',
          type: 'reward',
          category: 'subscription',
        );
      } catch (e) {
        print('ERROR: Failed to create free uses notification: $e');
      }

      return bonusUses;
    }

    return 0;
  }

  // Check if user can use the app (trial or subscription)
  static Future<bool> canUserUseApp(String userId, String userType) async {
    // Check if user has active subscription
    final subscription = await getUserSubscription(userId);
    if (subscription != null && subscription.isValidSubscription) {
      return true;
    }

    // Check trial usage
    final usage = await getUserUsageTracking(userId, userType);
    if (usage == null) {
      return true; // New user, allow usage
    }

    return !usage.hasExceededTrial;
  }

  // Get user subscription
  static Future<Subscription?> getUserSubscription(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keySubscription$userId';
    final subscriptionId = prefs.getString('${key}_id');

    if (subscriptionId != null && subscriptionId.isNotEmpty) {
      try {
        final Map<String, dynamic> data = {
          'id': subscriptionId,
          'user_id': userId,
          'user_type': prefs.getString('${key}_user_type') ?? '',
          'plan_type': prefs.getString('${key}_plan_type') ?? '',
          'status': prefs.getString('${key}_status') ?? 'pending',
          'expiry_date': prefs.getString('${key}_expiry'),
          'created_at':
              prefs.getString('${key}_created') ??
              DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        return Subscription.fromMap(data);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<Subscription> createOrUpdateSubscription(
    String userId,
    String userType,
    SubscriptionPlan plan,
    bool paymentSuccess,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keySubscription$userId';
    final now = DateTime.now().toUtc();
    final expiryDate = now.add(Duration(days: plan.durationInDays));

    final newStatus = paymentSuccess ? 'paid' : 'failed';

    print(
      "🔵 SUBSCRIPTION DEBUG: Creating/updating subscription for user: $userId",
    );
    print("   - Plan: ${plan.name} (${plan.id})");
    print("   - Duration: ${plan.durationInDays} days");
    print("   - Payment Success: $paymentSuccess");
    print("   - Expiry Date: $expiryDate");

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final existing = await SupabaseService.client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (existing.isNotEmpty) {
        final recordId = existing[0]['id'];
        print("✔ Found subscription record: $recordId");

        await SupabaseService.client
            .from('subscriptions')
            .update({
              'expiry_date': expiryDate.toIso8601String(),
              'plan_name': plan.name,
              'amount': plan.price,
              'updated_at': now.toIso8601String(),
              'status': newStatus,
              'user_type': userType,
              'plan_type': plan.id,
            })
            .eq('id', recordId);

        print("✔ Updated subscription $recordId");
        print("   - status: $newStatus");
        print("   - expiry_date: $expiryDate");
        print("   - plan: ${plan.name}");
      } else {
        print("⚠️ No subscription found for user $userId, inserting new one");

        await SupabaseService.client.from('subscriptions').insert({
          'user_id': userId,
          'user_type': userType,
          'plan_type': plan.id,
          'plan_name': plan.name,
          'amount': plan.price,
          'expiry_date': expiryDate.toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'status': newStatus,
        });

        print("✔ Inserted new subscription for user: $userId");
        print("   - status: $newStatus");
        print("   - expiry_date: $expiryDate");
        print("   - plan: ${plan.name}");
      }
    } catch (e) {
      print("❌ Supabase subscription error: $e");
    }

    final subscription = Subscription(
      id: '${userId}_${plan.id}_${now.millisecondsSinceEpoch}',
      userId: userId,
      userType: userType,
      planType: plan.id,
      status: paymentSuccess ? 'paid' : 'pending',
      expiryDate: expiryDate,
      createdAt: now,
      updatedAt: now,
    );

    await prefs.setString('${key}_id', subscription.id);
    await prefs.setString('${key}_user_type', subscription.userType);
    await prefs.setString('${key}_plan_type', subscription.planType);
    await prefs.setString('${key}_status', subscription.status);
    await prefs.setString(
      '${key}_expiry',
      subscription.expiryDate!.toIso8601String(),
    );
    await prefs.setString(
      '${key}_created',
      subscription.createdAt.toIso8601String(),
    );

    print("✔ Cached subscription locally");
    print("   - id: ${subscription.id}");
    print("   - status: ${subscription.status}");
    print("   - expiry_date: ${subscription.expiryDate}");

    return subscription;
  }

  static Future<int> getTrialLimitFromDatabase(
    String userId,
    String userType,
  ) async {
    try {
      final table = userType == 'Employer' ? 'employers' : 'helpers';
      final response = await SupabaseService.client
          .from(table)
          .select('trial_limit')
          .eq('id', userId)
          .single();

      return (response['trial_limit'] as num?)?.toInt() ?? 0;
    } catch (e) {
      print('ERROR: Failed to get trial limit from database: $e');
      return 0;
    }
  }

  static Future<Map<String, dynamic>> getCurrentUserSubscriptionStatus() async {
    final userId = await SessionService.getCurrentUserId();
    final userType = await SessionService.getCurrentUserType();

    if (userId == null || userType == null) {
      return {
        'canUse': false,
        'hasSubscription': false,
        'isTrialUser': false,
        'error': 'User not found',
      };
    }

    print('🔍 CHECKING SUBSCRIPTION STATUS for user: $userId');

    // CRITICAL: Always check database first to ensure fresh data after logout/login
    try {
      // Get ALL subscriptions for this user (in case they subscribed multiple times)
      final dbSubscriptions = await SupabaseService.client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('   Found ${dbSubscriptions.length} subscription records');

      // Find the most recent VALID subscription (not expired, status=paid)
      for (final subData in dbSubscriptions) {
        final subscription = Subscription.fromMap(subData);

        print('   Checking subscription:');
        print('     - id: ${subscription.id}');
        print('     - status: ${subscription.status}');
        print('     - expiry_date: ${subscription.expiryDate}');
        print('     - is_valid: ${subscription.isValidSubscription}');

        if (subscription.isValidSubscription) {
          print('✅ VALID SUBSCRIPTION FOUND - Updating cache');
          // Update local cache with fresh data
          await _updateLocalSubscriptionCache(userId, subscription);
          return {
            'canUse': true,
            'hasSubscription': true,
            'isTrialUser': false,
            'subscription': subscription,
          };
        }
      }

      // No valid subscription found in any records
      print('⚠️ No valid subscriptions found (all expired or inactive)');
    } catch (e) {
      print('ℹ️ Error querying subscriptions: $e');
    }

    // Fall back to local cache if database check failed
    final localSubscription = await getUserSubscription(userId);
    if (localSubscription != null && localSubscription.isValidSubscription) {
      print('✅ Found valid subscription in local cache');
      return {
        'canUse': true,
        'hasSubscription': true,
        'isTrialUser': false,
        'subscription': localSubscription,
      };
    }

    print('ℹ️ No valid subscription found, checking trial status...');

    // Fall back to trial mode
    final trialLimitFromDb = await getTrialLimitFromDatabase(userId, userType);
    final hasExceededTrial = trialLimitFromDb <= 0;
    final canUse = !hasExceededTrial;

    print('📊 Trial Status:');
    print('  - trial_limit: $trialLimitFromDb');
    print('  - has_exceeded: $hasExceededTrial');
    print('  - can_use: $canUse');

    final usage = UsageTracking(
      id: userId,
      userId: userId,
      userType: userType,
      usageCount: 0,
      trialLimit: trialLimitFromDb,
      lastUsedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return {
      'canUse': canUse,
      'hasSubscription': false,
      'isTrialUser': true,
      'usage': usage,
      'needsSubscription': hasExceededTrial,
    };
  }

  // Helper to update local subscription cache
  static Future<void> _updateLocalSubscriptionCache(
    String userId,
    Subscription subscription,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keySubscription$userId';

    await prefs.setString('${key}_id', subscription.id);
    await prefs.setString('${key}_user_type', subscription.userType);
    await prefs.setString('${key}_plan_type', subscription.planType);
    await prefs.setString('${key}_status', subscription.status);
    if (subscription.expiryDate != null) {
      await prefs.setString(
        '${key}_expiry',
        subscription.expiryDate!.toIso8601String(),
      );
    }
    await prefs.setString(
      '${key}_created',
      subscription.createdAt.toIso8601String(),
    );
  }

  static Future<void> recordAppUsage() async {
    final userId = await SessionService.getCurrentUserId();
    final userType = await SessionService.getCurrentUserType();

    if (userId == null || userType == null) return;

    final subscription = await getUserSubscription(userId);
    if (subscription?.isValidSubscription == true) {
      return; // Don't track usage for subscribed users
    }

    // Increment trial usage
    await incrementUsage(userId, userType);
  }

  // Clear subscription data
  static Future<void> clearSubscriptionData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final subscriptionKey = '$_keySubscription$userId';
    final usageKey = '$_keyUsageTracking$userId';

    // Clear subscription data
    await prefs.remove('${subscriptionKey}_id');
    await prefs.remove('${subscriptionKey}_user_type');
    await prefs.remove('${subscriptionKey}_plan_type');
    await prefs.remove('${subscriptionKey}_status');
    await prefs.remove('${subscriptionKey}_expiry');
    await prefs.remove('${subscriptionKey}_created');

    // Clear usage tracking
    await prefs.remove('${usageKey}_count');
    await prefs.remove('${usageKey}_last_used');
    await prefs.remove('${usageKey}_created');

    print('🧹 Cleared subscription data for user $userId');
  }

  // Force refresh subscription status by clearing cache
  // This is called after login to ensure fresh data from database
  static Future<void> forceRefreshSubscriptionStatus(String userId) async {
    print('🔄 Force refreshing subscription status for user $userId');
    await clearSubscriptionData(userId);
  }

  // Deduct trial limit from user (1 use per job post, service post, or job application)
  static Future<bool> deductTrialLimit(
    String userId,
    String userType,
    String table,
  ) async {
    try {
      // Get current trial limit
      final response = await SupabaseService.client
          .from(table)
          .select('trial_limit')
          .eq('id', userId)
          .single();

      final currentLimit = (response['trial_limit'] as num?)?.toInt() ?? 0;

      if (currentLimit <= 0) {
        print('WARNING: User $userId has no trial uses left');
        return false;
      }

      // Deduct 1 from trial limit
      await SupabaseService.client
          .from(table)
          .update({'trial_limit': currentLimit - 1})
          .eq('id', userId);

      print(
        '✓ Deducted trial limit for user $userId. New limit: ${currentLimit - 1}',
      );
      return true;
    } catch (e) {
      print('ERROR: Failed to deduct trial limit for user $userId: $e');
      return false;
    }
  }

  // Add bonus free uses when user completes 3 jobs (3 free uses added)
  static Future<void> addBonusTrialUses(
    String userId,
    String userType,
    String table,
  ) async {
    try {
      // Get current completed jobs count
      final response = await SupabaseService.client
          .from(table)
          .select('trial_limit, completed_jobs_count')
          .eq('id', userId)
          .single();

      final currentLimit = (response['trial_limit'] as num?)?.toInt() ?? 0;
      final completedJobs =
          (response['completed_jobs_count'] as num?)?.toInt() ?? 0;
      final newCompletedCount = completedJobs + 1;

      // Update completed jobs count
      await SupabaseService.client
          .from(table)
          .update({'completed_jobs_count': newCompletedCount})
          .eq('id', userId);

      // Check if user reached 3 completed jobs milestone
      if (newCompletedCount > 0 && newCompletedCount % 3 == 0) {
        final newLimit = currentLimit + 3;

        // Add 3 bonus uses
        await SupabaseService.client
            .from(table)
            .update({'trial_limit': newLimit})
            .eq('id', userId);

        print(
          '✓ Added 3 bonus trial uses for user $userId after completing $newCompletedCount jobs. New limit: $newLimit',
        );

        // Create notification
        try {
          await NotificationService.createNotification(
            recipientId: userId,
            title: 'Free Uses Awarded! 🎉',
            body:
                'Congratulations! You have earned 3 free uses after completing $newCompletedCount jobs.',
            type: 'reward',
            category: 'subscription',
          );
        } catch (e) {
          print('ERROR: Failed to create bonus notification: $e');
        }
      } else {
        print(
          '✓ Incremented completed jobs count for user $userId to $newCompletedCount',
        );
      }
    } catch (e) {
      print('ERROR: Failed to add bonus trial uses for user $userId: $e');
    }
  }
}
