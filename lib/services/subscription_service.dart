import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import '../models/subscription_plan.dart';
import '../models/usage_tracking.dart';
import '../utils/constants/subscription_constants.dart';
import 'session_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

class SubscriptionService {
  static const String _keyUsageTracking = 'usage_tracking_';
  static const String _keyCompletedJobs = 'completed_jobs_';
  static const String _keySubscription = 'subscription_';

  /// Create or update subscription record in Supabase and cache locally.
  /// - `paymentSuccess`: true => status 'paid', false => 'failed'
  /// - `checkoutUrl` and `paymentId` are optional and stored in DB if provided.
  static Future<Subscription> createOrUpdateSubscription(
    String userId,
    String userType, // kept in cache for UI even if DB doesn't have it
    SubscriptionPlan plan,
    bool paymentSuccess, {
    String? checkoutUrl,
    String? paymentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keySubscription$userId';
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: plan.durationInDays));
    final newStatus = paymentSuccess ? 'paid' : 'failed';

    print('🔵 SUBSCRIPTION: createOrUpdateSubscription()');
    print('   userId: $userId');
    print('   plan: ${plan.name} (${plan.id})');
    print('   expiry: $expiryDate');
    print('   status: $newStatus');

    try {
      // Try to find the most recent subscription row for this user
      final existing = await SupabaseService.client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (existing.isNotEmpty) {
        // Supabase returns row with numeric id (bigint). Keep it.
        final record = existing[0];
        final recordId = record['id'];
        print('✔ Found existing subscription record id: $recordId — updating');

        final updatePayload = <String, dynamic>{
          'expiry_date': expiryDate.toIso8601String(),
          'plan_name': plan.name,
          'amount': plan.price,
          'status': newStatus,
          // do not write user_type/plan_type — table doesn't have them
          // optionally write checkout/payment if provided
        };
        if (checkoutUrl != null) updatePayload['checkout_url'] = checkoutUrl;
        if (paymentId != null) updatePayload['payment_id'] = paymentId;

        await SupabaseService.client
            .from('subscriptions')
            .update(updatePayload)
            .eq('id', recordId);

        print('✔ Updated subscription (id: $recordId)');
      } else {
        print('⚠️ No existing subscription found — inserting new row');

        final insertPayload = <String, dynamic>{
          'user_id': userId,
          'expiry_date': expiryDate.toIso8601String(),
          'plan_name': plan.name,
          'amount': plan.price,
          'status': newStatus,
          // created_at has default now() in DB, but we set it explicitly for clarity
          'created_at': now.toIso8601String(),
        };
        if (checkoutUrl != null) insertPayload['checkout_url'] = checkoutUrl;
        if (paymentId != null) insertPayload['payment_id'] = paymentId;

        // Insert and fetch the inserted row so we have the DB-generated id
        final inserted = await SupabaseService.client
            .from('subscriptions')
            .insert(insertPayload)
            .select()
            .single();

        print('✔ Inserted subscription row: $inserted');
      }
    } catch (e) {
      print('❌ Supabase subscription error: $e');
      // Continue to populate local cache even if DB failed, so UX remains smooth.
    }

    // Build Subscription model for local cache
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

    // Cache locally (SharedPreferences)
    try {
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

      print('✔ Cached subscription locally for user $userId');
      print('   - id: ${subscription.id}');
      print('   - status: ${subscription.status}');
      print('   - expiry: ${subscription.expiryDate}');
    } catch (e) {
      print('⚠️ Failed to cache subscription locally: $e');
    }

    return subscription;
  }

  /// Fetch the current user's subscription status.
  /// Priority:
  /// 1. Query DB for subscriptions for this user (ordered by created_at desc)
  /// 2. If a valid (paid & not expired) subscription found -> cache locally & return it.
  /// 3. Fallback to local cache.
  /// 4. If none, fall back to trial logic.
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

    print('🔍 CHECK SUBSCRIPTION STATUS for user: $userId');

    try {
      final dbSubscriptions = await SupabaseService.client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('   Found ${dbSubscriptions.length} subscription rows in DB');
      for (final subData in dbSubscriptions) {
        try {
          final subscription = Subscription.fromMap(subData);
          print(
            '   - checking subscription id=${subData['id']} status=${subscription.status} expiry=${subscription.expiryDate}',
          );
          if (subscription.isValidSubscription) {
            print('✅ Valid DB subscription found - caching and returning');
            await _updateLocalSubscriptionCache(userId, subscription);
            return {
              'canUse': true,
              'hasSubscription': true,
              'isTrialUser': false,
              'subscription': subscription,
            };
          }
        } catch (e) {
          print('⚠️ Failed parsing subscription row: $e — skipping');
          continue;
        }
      }
    } catch (e) {
      print('ℹ️ Error querying subscriptions from DB: $e');
    }

    // Fallback: check local cache
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

    // Otherwise, trial logic
    print('ℹ️ No valid subscription found — falling back to trial checks');

    final trialLimitFromDb = await getTrialLimitFromDatabase(userId, userType);
    final hasExceededTrial = trialLimitFromDb <= 0;
    final canUse = !hasExceededTrial;

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

  /// Read subscription from local cache (SharedPreferences) and return Subscription model.
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
        print('⚠️ Failed to parse cached subscription: $e');
        return null;
      }
    }

    return null;
  }

  /// Update only the local SharedPreferences cache with given subscription
  static Future<void> _updateLocalSubscriptionCache(
    String userId,
    Subscription subscription,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keySubscription$userId';

    try {
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
      print('✔ Local subscription cache updated for $userId');
    } catch (e) {
      print('⚠️ Failed updating local subscription cache: $e');
    }
  }

  /// Clear subscription data (local cache + usage tracking)
  static Future<void> clearSubscriptionData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final subscriptionKey = '$_keySubscription$userId';
    final usageKey = '$_keyUsageTracking$userId';

    await prefs.remove('${subscriptionKey}_id');
    await prefs.remove('${subscriptionKey}_user_type');
    await prefs.remove('${subscriptionKey}_plan_type');
    await prefs.remove('${subscriptionKey}_status');
    await prefs.remove('${subscriptionKey}_expiry');
    await prefs.remove('${subscriptionKey}_created');

    await prefs.remove('${usageKey}_count');
    await prefs.remove('${usageKey}_last_used');
    await prefs.remove('${usageKey}_created');

    print('🧹 Cleared subscription data for user $userId');
  }

  /// Read trial limit from DB for the user (table depends on userType)
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

  /// Increment usage (for trial) — keeps backward compatibility with previous flow.
  static Future<int> incrementUsage(
    String userId,
    String userType, {
    int threshold = 3,
    int bonusUses = 3,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final completedKey = '$_keyCompletedJobs$userId';

    final tableName = userType == 'Employer' ? 'employers' : 'helpers';

    int current = 0;
    try {
      final response = await SupabaseService.client
          .from(tableName)
          .select('completed_jobs_count')
          .eq('id', userId)
          .single();
      current = (response['completed_jobs_count'] as num?)?.toInt() ?? 0;
      print(
        'DEBUG: Read completed_jobs_count from database: $current for user $userId',
      );
    } catch (e) {
      print('ERROR: Failed to read completed_jobs_count from database: $e');
      current = prefs.getInt('${completedKey}_count') ?? 0;
    }

    final newCount = current + 1;
    await prefs.setInt('${completedKey}_count', newCount);

    try {
      // Update the database with the new completed_jobs_count
      print(
        'DEBUG: Updating $tableName completed_jobs_count for user $userId to $newCount',
      );
      await SupabaseService.client
          .from(tableName)
          .update({'completed_jobs_count': newCount})
          .eq('id', userId);
      print(
        'DEBUG: Successfully updated completed_jobs_count in database for user $userId',
      );
    } catch (e) {
      print(
        'ERROR: Failed to update completed_jobs_count in database for user $userId: $e',
      );
    }

    if (newCount % threshold == 0) {
      final usageKey = '$_keyUsageTracking$userId';
      final currentLimit =
          prefs.getInt('${usageKey}_limit') ??
          SubscriptionConstants.getTrialLimitForUserType(userType);
      final newLimit = currentLimit + bonusUses;
      await prefs.setInt('${usageKey}_limit', newLimit);

      try {
        // Also update trial_limit in database
        print(
          'DEBUG: Updating $tableName trial_limit for user $userId to $newLimit',
        );
        await SupabaseService.client
            .from(tableName)
            .update({'trial_limit': newLimit})
            .eq('id', userId);
        print(
          'DEBUG: Successfully updated trial_limit in database for user $userId',
        );

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

  /// Deduct trial limit on the DB side for the appropriate table
  static Future<bool> deductTrialLimit(
    String userId,
    String userType,
    String table,
  ) async {
    try {
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

  /// Add bonus trial uses after completing required jobs
  static Future<int> addBonusTrialUses(
    String userId,
    String userType,
    String table, {
    int threshold = 3,
    int bonusUses = 3,
  }) async {
    try {
      return await incrementUsage(
        userId,
        userType,
        threshold: threshold,
        bonusUses: bonusUses,
      );
    } catch (e) {
      print('ERROR: Failed to add bonus trial uses for user $userId: $e');
      return 0;
    }
  }

  /// Force refresh subscription status by clearing cache and fetching fresh data from DB
  static Future<void> forceRefreshSubscriptionStatus(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keySubscription$userId';

      // Clear the local cache
      await prefs.remove('${key}_id');
      await prefs.remove('${key}_user_type');
      await prefs.remove('${key}_plan_type');
      await prefs.remove('${key}_status');
      await prefs.remove('${key}_expiry');
      await prefs.remove('${key}_created');

      print('✓ Cleared cached subscription for user $userId');

      // Fetch fresh subscription status from DB and cache it
      final status = await getCurrentUserSubscriptionStatus();
      print('✓ Refreshed subscription status for user $userId: $status');

      // If subscription found, cache it
      if (status['hasSubscription'] == true) {
        final subscription = status['subscription'] as Subscription;
        await _updateLocalSubscriptionCache(userId, subscription);
        print('✓ Cached fresh subscription data for user $userId');
      }
    } catch (e) {
      print('ERROR: Failed to force refresh subscription status: $e');
    }
  }
}
