class NotificationItem {
  final String id;
  final String recipientId;
  final String title;
  final String body;
  final String
  type; // e.g. 'message', 'job', 'service', 'subscription', 'job_application', 'application_accepted', 'application_rejected'
  final String category; // e.g. 'new', 'previous', 'important', 'update'
  final String? targetId; // id of job/service/conversation etc.
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    this.category = 'update',
    this.targetId,
    required this.timestamp,
    required this.isRead,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> data) {
    return NotificationItem(
      id: data['id'] as String? ?? '',
      recipientId: data['recipient_id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? 'generic',
      category: data['category'] as String? ?? 'update',
      targetId: data['target_id'] as String?,
      timestamp: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : DateTime.now(),
      isRead: data['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'recipient_id': recipientId,
    'title': title,
    'body': body,
    'type': type,
    'category': category,
    'target_id': targetId,
    'timestamp': timestamp.toIso8601String(),
    'is_read': isRead,
  };
}
