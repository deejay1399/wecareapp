import 'package:flutter/material.dart';
import '../../models/job_posting.dart';
import '../../models/helper_service_posting.dart';
import '../../services/subscription_service.dart';
import '../../services/database_messaging_service.dart';
import '../../services/job_posting_service.dart';
import '../../services/helper_service_posting_service.dart';
import '../../services/session_service.dart';
import '../../services/notification_service.dart';
import '../notifications/notifications_screen.dart';
import '../../widgets/cards/job_posting_card.dart';
import '../../widgets/cards/helper_service_posting_card.dart';
import '../../widgets/buttons/post_job_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/subscription/subscription_status_banner.dart';
import '../employer/employer_subscription_screen.dart';
import '../employer/post_job_screen.dart';
import '../employer/job_details_screen.dart';
import '../employer/all_services_screen.dart';
import '../employer/service_details_screen.dart';
import '../messaging/conversations_screen.dart';
import '../shared/completed_jobs_screen.dart';
import '../../language_manager.dart';
import '../../localization_manager.dart';

class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({super.key});

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  Map<String, dynamic>? _subscriptionStatus;
  int _unreadMessageCount = 0;
  int _unreadNotificationCount = 0;
  List<JobPosting> _recentJobPostings = [];
  List<HelperServicePosting> _availableServices = [];
  bool _isLoadingJobs = true;
  bool _isLoadingServices = true;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Force refresh subscription status before loading other data
    // This ensures we get fresh data after logout/login
    try {
      final userId = await SessionService.getCurrentUserId();
      if (userId != null) {
        await SubscriptionService.forceRefreshSubscriptionStatus(userId);
      }
    } catch (e) {
      debugPrint('Error refreshing subscription: $e');
    }

    // Then load all other data
    await _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSubscriptionStatus(),
      _loadUnreadMessageCount(),
      _loadUnreadNotificationCount(),
      _loadRecentJobPostings(),
      _loadAvailableServices(),
    ]);
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final status =
          await SubscriptionService.getCurrentUserSubscriptionStatus();
      if (mounted) {
        setState(() {
          _subscriptionStatus = status;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final count = await DatabaseMessagingService.getTotalUnreadCount();
      if (mounted) {
        setState(() {
          _unreadMessageCount = count;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadRecentJobPostings() async {
    setState(() {
      _isLoadingJobs = true;
    });

    try {
      // Get current employer
      final employer = await SessionService.getCurrentEmployer();
      if (employer != null) {
        // Load recent job postings (limit to 3)
        final allJobPostings = await JobPostingService.getJobPostingsByEmployer(
          employer.id,
        );

        if (mounted) {
          setState(() {
            _recentJobPostings = allJobPostings.take(3).toList();
            _isLoadingJobs = false;
          });
        }
      } else {
        setState(() {
          _isLoadingJobs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingJobs = false;
        });
      }
    }
  }

  Future<void> _loadAvailableServices() async {
    setState(() {
      _isLoadingServices = true;
    });

    try {
      // Load active helper service postings (limit to 3)
      final allServices =
          await HelperServicePostingService.getActiveServicePostings();

      if (mounted) {
        setState(() {
          _availableServices = allServices.take(3).toList();
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
      }
    }
  }

  void _onSubscriptionTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmployerSubscriptionScreen(),
      ),
    );
  }

  void _onMessagesTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConversationsScreen()),
    ).then((_) {
      // Refresh unread count when returning
      _loadUnreadMessageCount();
    });

    // Also schedule a short delayed refresh to catch async updates
    Future.delayed(const Duration(milliseconds: 400), _loadUnreadMessageCount);
  }

  void _onNotificationsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    ).then((_) {
      // refresh unread notification count when returning
      _loadUnreadNotificationCount();
    });

    Future.delayed(
      const Duration(milliseconds: 400),
      _loadUnreadNotificationCount,
    );
  }

  void _onCompletedJobsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CompletedJobsScreen()),
    );
  }

  void _onPostJob(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostJobScreen()),
    );

    if (!context.mounted) return;

    // If job was posted successfully, refresh data and show success message
    if (result == true) {
      _loadRecentJobPostings(); // Refresh job postings
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationManager.translate('job_post_success_message'),
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onJobTap(BuildContext context, JobPosting job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailsScreen(jobPosting: job),
      ),
    ).then((result) {
      // Refresh job postings if job was updated or deleted
      if (result != null) {
        _loadRecentJobPostings();
      }
    });
  }

  void _onServiceTap(BuildContext context, HelperServicePosting service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(servicePosting: service),
      ),
    );
  }

  void _onSeeAllServices() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AllServicesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF1565C0),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${LocalizationManager.translate('good')} ${LocalizationManager.translate(_getGreeting())}!',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  LocalizationManager.translate('find_help'),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _onNotificationsTap,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1565C0,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF1565C0,
                                          ).withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.notifications_outlined,
                                          color: Color(0xFF1565C0),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    if (_unreadNotificationCount > 0)
                                      Positioned(
                                        right: -4,
                                        top: -4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: Text(
                                            _unreadNotificationCount > 99
                                                ? '99+'
                                                : _unreadNotificationCount
                                                      .toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 48,
                                height: 48,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1565C0,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF1565C0,
                                    ).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.language,
                                    color: Color(0xFF1565C0),
                                    size: 24,
                                  ),
                                  offset: const Offset(
                                    0,
                                    50,
                                  ), // 👈 dropdown appears BELOW icon
                                  color: Colors.white.withOpacity(
                                    0.9,
                                  ), // 👈 slight transparency
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  onSelected: (String code) async {
                                    await LanguageManager.setLanguage(code);
                                    await LocalizationManager.loadLanguage();
                                    if (context.mounted) setState(() {});
                                  },
                                  itemBuilder: (BuildContext context) => const [
                                    PopupMenuItem(
                                      value: 'English',
                                      child: Text(
                                        'English',
                                        style: TextStyle(
                                          color: Color(0xFF1565C0),
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'Tagalog',
                                      child: Text(
                                        'Tagalog',
                                        style: TextStyle(
                                          color: Color(0xFF1565C0),
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'Cebuano',
                                      child: Text(
                                        'Cebuano',
                                        style: TextStyle(
                                          color: Color(0xFF1565C0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Subscription Status Banner
                if (_subscriptionStatus != null)
                  SubscriptionStatusBanner(
                    subscriptionStatus: _subscriptionStatus!,
                    onTap: _onSubscriptionTap,
                  ),

                // Post Job Button
                PostJobButton(onPressed: () => _onPostJob(context)),

                const SizedBox(height: 24),

                // Quick Actions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SectionHeader(
                    title: LocalizationManager.translate('quick_actions'),
                    subtitle: LocalizationManager.translate('manage_account'),
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Action Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          LocalizationManager.translate('messages'),
                          LocalizationManager.translate('chat_with_helpers'),
                          Icons.chat_bubble_outline,
                          const Color(0xFF1565C0),
                          _onMessagesTap,
                          badgeCount: _unreadMessageCount,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          LocalizationManager.translate('completed_jobs'),
                          LocalizationManager.translate('rate_your_hires'),
                          Icons.history_outlined,
                          const Color(0xFF10B981),
                          _onCompletedJobsTap,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          LocalizationManager.translate('services'),
                          LocalizationManager.translate('browse_helpers'),
                          Icons.storefront_outlined,
                          const Color(0xFFFF8A50),
                          _onSeeAllServices,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Recent Job Postings Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SectionHeader(
                    title: LocalizationManager.translate('recent_jobs'),
                    subtitle: LocalizationManager.translate('manage_employer'),
                    onSeeAll: _recentJobPostings.length >= 3
                        ? () {
                            // Navigate to the My Jobs tab (index 1 in the bottom navigation)
                            if (context.mounted) {
                              DefaultTabController.of(context).animateTo(1);
                            }
                          }
                        : null,
                  ),
                ),

                const SizedBox(height: 16),

                // Job Postings List or Empty State
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _isLoadingJobs
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        )
                      : _recentJobPostings.isEmpty
                      ? _buildEmptyJobsState()
                      : Column(
                          children: _recentJobPostings.map((job) {
                            return JobPostingCard(
                              jobPosting: job,
                              onTap: () => _onJobTap(context, job),
                            );
                          }).toList(),
                        ),
                ),

                const SizedBox(height: 32),

                // Helper Services Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SectionHeader(
                    title: LocalizationManager.translate('available_services'),
                    subtitle: LocalizationManager.translate(
                      'browse_by_service_type',
                    ),
                    onSeeAll: _availableServices.isNotEmpty
                        ? _onSeeAllServices
                        : null,
                  ),
                ),

                const SizedBox(height: 16),

                // Services List or Empty State
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _isLoadingServices
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        )
                      : _availableServices.isEmpty
                      ? _buildEmptyServicesState()
                      : Column(
                          children: _availableServices.map((service) {
                            return HelperServicePostingCard(
                              servicePosting: service,
                              onTap: () => _onServiceTap(context, service),
                            );
                          }).toList(),
                        ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  // language options are built inline in the popup menu, helper removed

  Widget _buildEmptyJobsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.work_outline,
              size: 40,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            LocalizationManager.translate('job_post_success_message'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LocalizationManager.translate('post_first_job'),
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyServicesState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.search_off,
              size: 40,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            LocalizationManager.translate('no_services'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 8),
          Text(
            LocalizationManager.translate('services_coming_soon'),
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    int? badgeCount,
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      shadowColor: color.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
