import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/notification_item.dart';
import '../../services/notification_service.dart';
import '../../services/job_posting_service.dart';
import '../../services/helper_service_posting_service.dart';
import '../employer/job_details_screen.dart';
import '../employer/service_details_screen.dart';
import '../../localization_manager.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<NotificationItem>> _future;
  late TabController _tabController;
  String _filterType = 'all'; // all, unread, new, passed
  late StreamSubscription<List<Map<String, dynamic>>> _notificationListener;
  late Timer _timeRefreshTimer;

  @override
  void initState() {
    super.initState();
    _future = NotificationService.getNotifications();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Initialize listeners
    _setupRealtimeListener();
    _setupTimeRefreshTimer();
  }

  void _setupRealtimeListener() {
    // Listen for real-time notifications from Supabase
    try {
      _notificationListener = NotificationService.getRealtimeNotifications()
          .listen(
            (notificationsList) {
              if (mounted) {
                setState(() {
                  _future = Future.value(
                    notificationsList
                        .map((n) => NotificationItem.fromMap(n))
                        .toList(),
                  );
                });
              }
            },
            onError: (error) {
              print('ERROR: Real-time listener error: $error');
            },
          );
    } catch (e) {
      print('ERROR: Failed to setup real-time listener: $e');
    }
  }

  void _setupTimeRefreshTimer() {
    // Refresh time display every minute
    _timeRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update _timeAgo for all items
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationListener.cancel();
    _timeRefreshTimer.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _filterType = ['all', 'read', 'unread'][_tabController.index];
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = NotificationService.getNotifications();
    });
    await _future;
  }

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  List<NotificationItem> _filterNotifications(List<NotificationItem> items) {
    // Sort from latest to oldest
    final sorted = items..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    switch (_filterType) {
      case 'read':
        return sorted.where((n) => n.isRead).toList();
      case 'unread':
        return sorted.where((n) => !n.isRead).toList();
      default:
        return sorted;
    }
  }

  String _getDateString(DateTime dt) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (dt.year == today.year &&
        dt.month == today.month &&
        dt.day == today.day) {
      return 'Today';
    } else if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${dt.day} ${_getMonthName(dt.month)} ${dt.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Map<String, List<NotificationItem>> _groupByDate(
    List<NotificationItem> items,
  ) {
    final grouped = <String, List<NotificationItem>>{};

    for (var item in items) {
      final dateStr = _getDateString(item.timestamp);
      grouped.putIfAbsent(dateStr, () => []);
      grouped[dateStr]!.add(item);
    }

    return grouped;
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_outline;
      case 'job':
      case 'job_application':
      case 'application_accepted':
      case 'application_rejected':
        return Icons.work_outline;
      case 'service':
        return Icons.storefront_outlined;
      case 'subscription':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'message':
        return const Color(0xFF1565C0);
      case 'job':
      case 'job_application':
      case 'application_accepted':
      case 'application_rejected':
        return const Color(0xFF10B981);
      case 'service':
        return const Color(0xFFFF8A50);
      case 'subscription':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'new':
        return const Color(0xFFEF4444);
      case 'previous':
        return const Color(0xFF6B7280);
      case 'important':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  void _openTarget(NotificationItem item) async {
    // mark read
    await NotificationService.markAsRead(item.id);

    if (!context.mounted) return;

    try {
      // Handle job-related notifications
      if ((item.type == 'message' ||
              item.type == 'job' ||
              item.type == 'job_application' ||
              item.type == 'application_accepted' ||
              item.type == 'application_rejected') &&
          item.targetId != null) {
        final job = await JobPostingService.getJobPostingById(item.targetId!);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => JobDetailsScreen(jobPosting: job)),
        );
        return;
      }

      if (item.type == 'service' && item.targetId != null) {
        final service = await HelperServicePostingService.getServicePostingById(
          item.targetId!,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => ServiceDetailsScreen(servicePosting: service),
          ),
        );
        return;
      }

      if (item.type == 'subscription') {
        // open subscription screen if needed
        Navigator.pop(context);
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationManager.translate('error_opening_notification'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(LocalizationManager.translate('notifications')),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Read'),
            Tab(text: 'Unread'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF1565C0),
        child: FutureBuilder<List<NotificationItem>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1565C0)),
              );
            }
            final allItems = snap.data ?? [];
            final items = _filterNotifications(allItems);

            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 80,
                    color: const Color(0xFF1565C0).withOpacity(0.2),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      LocalizationManager.translate('no_notifications'),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            }

            // Group notifications by date
            final groupedByDate = _groupByDate(items);
            final dateKeys = groupedByDate.keys.toList();

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                // Calculate item index
                int currentIndex = 0;
                for (int i = 0; i < dateKeys.length; i++) {
                  if (currentIndex == index) {
                    // This is a date divider
                    return _buildDateDivider(dateKeys[i]);
                  }
                  currentIndex++;

                  final dateNotifications = groupedByDate[dateKeys[i]]!;
                  if (currentIndex + dateNotifications.length > index) {
                    // This is a notification
                    final notificationIndex = index - currentIndex;
                    final item = dateNotifications[notificationIndex];
                    return _buildNotificationCard(item);
                  }
                  currentIndex += dateNotifications.length;
                }
                return const SizedBox.shrink();
              },
              itemCount: () {
                // Count: dates + all notifications
                return dateKeys.length + items.length;
              }(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateDivider(String dateStr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: const Color(0xFF9CA3AF).withOpacity(0.3),
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              dateStr,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: const Color(0xFF9CA3AF).withOpacity(0.3),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    final color = _getColorForType(item.type);
    final categoryColor = _getColorForCategory(item.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: item.isRead ? 1 : 2,
        borderRadius: BorderRadius.circular(12),
        shadowColor: color.withOpacity(0.15),
        child: InkWell(
          onTap: () => _openTarget(item),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: item.isRead ? Colors.white : const Color(0xFFF0F9FF),
              border: Border.all(
                color: item.isRead
                    ? Colors.transparent
                    : color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.2), width: 1),
                  ),
                  child: Center(
                    child: Icon(
                      _getIconForType(item.type),
                      color: color,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!item.isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.body,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _timeAgo(item.timestamp),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
