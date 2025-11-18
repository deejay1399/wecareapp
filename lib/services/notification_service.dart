import '../models/notification_item.dart';
import 'supabase_service.dart';
import 'session_service.dart';

class NotificationService {
  static const String _tableName = 'notifications';

  /// Create a new notification
  static Future<void> createNotification({
    required String recipientId,
    String title = 'Notification',
    String body = '',
    String type = 'update',
    String category = 'update',
    String? targetId,
  }) async {
    try {
      final data = {
        'recipient_id': recipientId,
        'title': title,
        'body': body,
        'type': type,
        'category': category,
        'target_id': targetId,
        'is_read': false,
      };

      print(
        'DEBUG NotificationService: Creating notification with data: $data',
      );

      await SupabaseService.client
          .from(_tableName)
          .insert(data)
          .select()
          .single();

      print('DEBUG NotificationService: Notification inserted successfully');
    } catch (e) {
      print('ERROR NotificationService: Failed to create notification: $e');
      rethrow;
    }
  }

  /// Fetch notifications for current user
  static Future<List<NotificationItem>> getNotifications() async {
    final userId = await SessionService.getCurrentUserId();
    if (userId == null) return [];

    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('recipient_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => NotificationItem.fromMap(item))
          .toList();
    } catch (e) {
      print('ERROR fetching notifications: $e');
      return [];
    }
  }

  /// Get unread count
  static Future<int> getUnreadCount() async {
    final userId = await SessionService.getCurrentUserId();
    if (userId == null) return 0;

    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('id')
          .eq('recipient_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('ERROR fetching unread count: $e');
      return 0;
    }
  }

  /// Mark single notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseService.client
          .from(_tableName)
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('ERROR marking as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    final userId = await SessionService.getCurrentUserId();
    if (userId == null) return;

    try {
      await SupabaseService.client
          .from(_tableName)
          .update({'is_read': true})
          .eq('recipient_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('ERROR marking all as read: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await SupabaseService.client
          .from(_tableName)
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      print('ERROR deleting notification: $e');
    }
  }

  /// Get real-time stream of notifications for current user
  static Stream<List<Map<String, dynamic>>> getRealtimeNotifications() async* {
    final userId = await SessionService.getCurrentUserId();
    if (userId == null) return;

    try {
      yield* SupabaseService.client
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('recipient_id', userId)
          .order('created_at', ascending: false)
          .map((List<dynamic> data) => List<Map<String, dynamic>>.from(data));
    } catch (e) {
      print('ERROR in real-time listener: $e');
    }
  }
}
