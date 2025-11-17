import 'package:flutter/material.dart';
import '../../models/notification_item.dart';
import '../../services/notification_service.dart';
import '../../services/job_posting_service.dart';
import '../../services/helper_service_posting_service.dart';
import '../employer/job_details_screen.dart';
import '../employer/service_details_screen.dart';
import '../messaging/conversations_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _future = NotificationService.getNotifications();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _filterType = ['all', 'unread', 'new', 'previous'][_tabController.index];
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
    switch (_filterType) {
      case 'unread':
        return items.where((n) => !n.isRead).toList();
      case 'new':
        return items.where((n) => n.category == 'new').toList();
      case 'previous':
        return items.where((n) => n.category == 'previous').toList();
      default:
        return items;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_outline;
      case 'job':
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
      if (item.type == 'message') {
        // If we have a conversation id in targetId, open ConversationsScreen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const ConversationsScreen()),
        );
        return;
      }

      if (item.type == 'job' && item.targetId != null) {
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
            Tab(text: 'Unread'),
            Tab(text: 'New'),
            Tab(text: 'Previous'),
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

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = items[index];
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
                          color: item.isRead
                              ? Colors.white
                              : const Color(0xFFF0F9FF),
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
                                border: Border.all(
                                  color: color.withOpacity(0.2),
                                  width: 1,
                                ),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: categoryColor.withOpacity(
                                            0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: categoryColor.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          item.category.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: categoryColor,
                                          ),
                                        ),
                                      ),
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
              },
              itemCount: items.length,
            );
          },
        ),
      ),
    );
  }
}
