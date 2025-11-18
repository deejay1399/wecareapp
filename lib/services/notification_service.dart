import '../models/notification_item.dart';
import 'supabase_service.dart';
import 'session_service.dart';

class NotificationService {
  static const String _tableName = 'notifications';

  /// Create a new notification
  static Future<void> createNotification({
    required String recipientId,
    required String recipientType,
    required String title,
    required String body,
    required String type,
    String category = 'update',
    String? targetId,
  }) async {
    try {
      await SupabaseService.client.from(_tableName).insert({
        'recipient_id': recipientId,
        'recipient_type': recipientType,
        'title': title,
        'body': body,
        'type': type,
        'category': category,
        'target_id': targetId,
        'is_read': false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  /// Fetch all notifications for current user ordered by timestamp desc
  static Future<List<NotificationItem>> getNotifications() async {
    final userId = await SessionService.getCurrentUserId();
    if (userId == null) return [];

    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('recipient_id', userId)
          .order('timestamp', ascending: false);

      return (response as List)
          .map((item) => NotificationItem.fromMap(item))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get count of unread notifications for current user
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
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark a notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseService.client
          .from(_tableName)
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for current user
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
      print('Error marking all as read: $e');
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
      print('Error deleting notification: $e');
    }
  }
}
