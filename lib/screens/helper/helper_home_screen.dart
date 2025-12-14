import 'package:flutter/material.dart';
import 'package:wecareapp/services/rating_service.dart';
import 'package:wecareapp/widgets/rating/star_rating_display.dart';
import '../../models/job_posting.dart';
import '../../models/helper_service_posting.dart';
import '../../models/helper.dart';
import '../../services/subscription_service.dart';
import '../../services/database_messaging_service.dart';
import '../../services/job_posting_service.dart';
import '../../services/application_service.dart';
import '../../services/helper_service_posting_service.dart';
import '../../services/session_service.dart';
import '../../services/report_service.dart';
import '../../widgets/cards/helper_service_posting_card.dart';
import '../../widgets/buttons/post_service_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/subscription/subscription_status_banner.dart';
import '../../widgets/dialogs/report_dialog.dart';
import '../helper/helper_subscription_screen.dart';
import '../helper/apply_job_screen.dart';
import '../helper/post_service_screen.dart';
import '../helper/edit_service_screen.dart';
import '../messaging/conversations_screen.dart';
import '../shared/completed_jobs_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../models/rating_statistics.dart';
import '../../services/notification_service.dart';

import '../../localization_manager.dart';
import '../../language_manager.dart';

class HelperHomeScreen extends StatefulWidget {
  const HelperHomeScreen({super.key});

  @override
  State<HelperHomeScreen> createState() => _HelperHomeScreenState();
}

class _HelperHomeScreenState extends State<HelperHomeScreen> {
  Map<String, dynamic>? _subscriptionStatus;
  int _unreadMessageCount = 0;
  int _unreadNotificationCount = 0;
  Helper? _currentHelper;
  List<JobPosting> _matchedJobs = [];
  List<HelperServicePosting> _myServices = [];
  bool _isLoadingJobs = true;
  bool _isLoadingServices = true;
  final _ratingService = RatingService();
  Set<String> _appliedJobIds = {};
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
    _loadCurrentHelper();
    _loadSubscriptionStatus();
    _loadUnreadMessageCount();
    _loadUnreadNotificationCount();
    _loadMatchedJobs(); // Load all job opportunities
    _loadAppliedJobs(); // Load applied job IDs
  }

  Future<void> _loadAppliedJobs() async {
    try {
      if (_currentHelper != null) {
        final applications = await ApplicationService.getApplicationsByHelper(
          _currentHelper!.id,
        );
        if (mounted) {
          setState(() {
            _appliedJobIds = applications.map((app) => app.jobId).toSet();
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadCurrentHelper() async {
    try {
      final helper = await SessionService.getCurrentHelper();
      if (helper != null && mounted) {
        setState(() {
          _currentHelper = helper;
        });
        _loadMyServices();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadMatchedJobs() async {
    setState(() {
      _isLoadingJobs = true;
    });

    try {
      // Use getRecentJobPostings with limit 100
      List<JobPosting> recentJobs =
          await JobPostingService.getRecentJobPostings(limit: 100);
      // Take only the first 2 jobs for the home screen
      final jobs = recentJobs.take(2).toList();

      if (mounted) {
        setState(() {
          _matchedJobs = jobs;
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

  Future<void> _loadMyServices() async {
    if (_currentHelper == null) return;

    setState(() {
      _isLoadingServices = true;
    });

    try {
      final services =
          await HelperServicePostingService.getServicePostingsByHelper(
            _currentHelper!.id,
          );

      if (mounted) {
        setState(() {
          _myServices = services;
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

  void _onSubscriptionTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelperSubscriptionScreen()),
    );
  }

  void _onMessagesTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/conversations'),
        builder: (context) => const ConversationsScreen(),
      ),
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

  void _onPostService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostServiceScreen()),
    ).then((_) {
      // Refresh services when returning
      _loadMyServices();
    });
  }

  Future<void> _onJobTap(BuildContext context, JobPosting job) async {
    if (_currentHelper == null) return;

    // Navigate to apply screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ApplyJobScreen(jobPosting: job)),
    );

    if (result == true) {
      if (mounted) {
        // Application submitted successfully
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translate(
                'application_submitted_successfully!',
              ),
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        // Refresh matched jobs
        _loadMatchedJobs();
      }
    }
  }

  void _onServiceTap(BuildContext context, HelperServicePosting service) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditServiceScreen(servicePosting: service),
      ),
    );

    // Always refresh the services list when returning from edit screen
    // This handles updates, deletions, and status changes
    _loadMyServices();

    if (result == 'deleted') {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translate('service_deleted_successfully'),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  void _onEditService(
    BuildContext context,
    HelperServicePosting service,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditServiceScreen(servicePosting: service),
      ),
    );

    // Always refresh the services list when returning from edit screen
    // This handles updates, deletions, and status changes
    _loadMyServices();

    if (result == 'deleted') {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translate('service_deleted_successfully'),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  Widget _buildEmptyJobsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.work_outline,
              size: 40,
              color: Color(0xFFFF8A50),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            LocalizationManager.translate('no_job_opportunities_available'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LocalizationManager.translate(
              'check_back_later_for_new_job_postings',
            ),
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
              color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 40,
              color: Color(0xFFFF8A50),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            LocalizationManager.translate('no_services_posted_yet'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LocalizationManager.translate('start_offering_your_services'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
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
                                LocalizationManager.translate(
                                  'ready_to_help_today',
                                ),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF8A50),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                                    0xFFFF8A50,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFF8A50,
                                    ).withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.notifications_outlined,
                                    color: Color(0xFFFF8A50),
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
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      _unreadNotificationCount > 99
                                          ? '99+'
                                          : _unreadNotificationCount.toString(),
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
                            color: const Color(0xFFFF8A50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFF8A50).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.language,
                              color: Color(0xFFFF8A50),
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
                                  style: TextStyle(color: Color(0xFFFF8A50)),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'Tagalog',
                                child: Text(
                                  'Tagalog',
                                  style: TextStyle(color: Color(0xFFFF8A50)),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'Cebuano',
                                child: Text(
                                  'Cebuano',
                                  style: TextStyle(color: Color(0xFFFF8A50)),
                                ),
                              ),
                            ],
                          ),
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

              // Quick Actions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SectionHeader(
                  title: LocalizationManager.translate('quick_actions'),
                  subtitle: LocalizationManager.translate(
                    'manage_your_helper_profile',
                  ),
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
                        LocalizationManager.translate('chat_with_employers'),
                        Icons.chat_bubble_outline,
                        const Color(0xFFFF8A50),
                        _onMessagesTap,
                        badgeCount: _unreadMessageCount,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        LocalizationManager.translate('completed_jobs'),
                        LocalizationManager.translate(
                          'rate_your_past_experiences',
                        ),
                        Icons.history_outlined,
                        const Color(0xFF10B981),
                        _onCompletedJobsTap,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Post Service Button
              PostServiceButton(onPressed: () => _onPostService(context)),

              const SizedBox(height: 32),

              // Recent Job Opportunities Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SectionHeader(
                  title: LocalizationManager.translate(
                    'latest_job_opportunities',
                  ),
                  subtitle: LocalizationManager.translate(
                    'explore_all_available_job_postings',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Job Opportunities List or Empty State
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _isLoadingJobs
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF8A50),
                          ),
                        ),
                      )
                    : _matchedJobs.isEmpty
                    ? _buildEmptyJobsState()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _matchedJobs.length,
                        itemBuilder: (context, index) {
                          print('Job #$index: ${_matchedJobs[index].toMap()}');
                          return _buildJobCard(_matchedJobs[index]);
                        },
                      ),
              ),

              const SizedBox(height: 32),

              // My Posted Services Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SectionHeader(
                  title: LocalizationManager.translate('my_posted_services'),
                  subtitle: LocalizationManager.translate(
                    'manage_your_service_offerings',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // My Services List or Empty State
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _isLoadingServices
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF8A50),
                          ),
                        ),
                      )
                    : _myServices.isEmpty
                    ? _buildEmptyServicesState()
                    : Column(
                        children: _myServices.take(2).map((service) {
                          return HelperServicePostingCard(
                            servicePosting: service,
                            onTap: () => _onServiceTap(context, service),
                            onEdit: () => _onEditService(context, service),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(JobPosting job) {
    return _HomeJobCard(
      job: job,
      onTap: () => _onJobTap(context, job),
      ratingService: _ratingService,
      isApplied: _appliedJobIds.contains(job.id),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return LocalizationManager.translate('morning');
    if (hour < 17) return LocalizationManager.translate('afternoon');
    return LocalizationManager.translate('evening');
  }
}

// Helper widget for job cards with independent rating loading
class _HomeJobCard extends StatefulWidget {
  final JobPosting job;
  final VoidCallback onTap;
  final RatingService ratingService;
  final bool isApplied;

  const _HomeJobCard({
    required this.job,
    required this.onTap,
    required this.ratingService,
    required this.isApplied,
  });

  @override
  State<_HomeJobCard> createState() => _HomeJobCardState();
}

class _HomeJobCardState extends State<_HomeJobCard> {
  RatingStatistics? _employerRatingStats;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    _loadEmployerRatingStats();
  }

  Future<void> _loadEmployerRatingStats() async {
    try {
      final stats = await widget.ratingService.getUserRatingStatistics(
        widget.job.employerId,
        'employer',
      );

      if (mounted) {
        setState(() {
          _employerRatingStats = stats;
          _isLoadingRating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRating = false;
        });
      }
    }
  }

  String _formatExpiryDate(DateTime expiryDate) {
    final hour12 = expiryDate.hour > 12
        ? expiryDate.hour - 12
        : (expiryDate.hour == 0 ? 12 : expiryDate.hour);
    final period = expiryDate.hour >= 12 ? 'PM' : 'AM';
    final hour = hour12.toString().padLeft(2, '0');
    final minute = expiryDate.minute.toString().padLeft(2, '0');
    return '${expiryDate.day.toString().padLeft(2, '0')}/${expiryDate.month.toString().padLeft(2, '0')}/${expiryDate.year} $hour:$minute $period';
  }

  void _showReportDialog(BuildContext context) async {
    try {
      final currentHelper = await SessionService.getCurrentHelper();

      if (currentHelper == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translate('please_login_to_report'),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Prevent users from reporting themselves
      if (currentHelper.id == widget.job.employerId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translate('cannot_report_yourself'),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => ReportDialog(
          type: 'job_posting',
          onSubmit: (reason, description) async {
            try {
              // Get employer name from job if available
              final reportedUserName = widget.job.employer != null
                  ? '${widget.job.employer!.firstName} ${widget.job.employer!.lastName}'
                  : '';

              await ReportService.submitReport(
                reportedBy: currentHelper.id,
                reportedUser: widget.job.employerId,
                reason: reason,
                type: 'job_posting',
                referenceId: widget.job.id,
                description: description,
                reporterName:
                    '${currentHelper.firstName} ${currentHelper.lastName}',
                reportedUserName: reportedUserName,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      LocalizationManager.translate(
                        'report_submitted_successfully',
                      ),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      LocalizationManager.translate('failed_to_submit_report'),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationManager.translate('failed_to_submit_report'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: const Color(0xFFFF8A50).withValues(alpha: 0.1),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and salary with report button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (widget.job.employer?.fullName != null &&
                                widget.job.employer!.fullName.trim().isNotEmpty)
                            ? widget.job.employer!.fullName
                            : 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    Text(
                      '₱${widget.job.salary.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF6B7280),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.flag_outlined,
                                size: 18,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(LocalizationManager.translate('report')),
                            ],
                          ),
                          onTap: () => _showReportDialog(context),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(
                  "${LocalizationManager.translate('age')}: ${widget.job.employer?.age ?? 'N/A'}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Payment frequency and location
                Row(
                  children: [
                    Text(
                      widget.job.paymentFrequency,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.job.barangay,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "${LocalizationManager.translate('job_title')}: ${widget.job.title}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  "${LocalizationManager.translate('job_description')}: ${widget.job.description}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Employer Rating
                if (!_isLoadingRating) ...[
                  if (_employerRatingStats != null &&
                      _employerRatingStats!.hasRatings) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A50).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF8A50).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.business,
                            size: 16,
                            color: Color(0xFFFF8A50),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocalizationManager.translate(
                                    'employer_rating',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                StarRatingDisplay(
                                  rating: _employerRatingStats!.averageRating,
                                  totalRatings:
                                      _employerRatingStats!.totalRatings,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else if (_employerRatingStats != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.business,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              LocalizationManager.translate('no_ratings_yet'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],

                // Required skills
                if (widget.job.requiredSkills.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.job.requiredSkills.take(3).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF8A50),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Expiration date display and Apply button on same row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    LocalizationManager.translate('expires_at'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.job.expiresAt != null
                                        ? _formatExpiryDate(
                                            widget.job.expiresAt!,
                                          )
                                        : LocalizationManager.translate(
                                            'no_expiration_date',
                                          ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: widget.isApplied ? null : widget.onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isApplied
                            ? Colors.grey[400]
                            : const Color(0xFFFF8A50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.isApplied
                            ? LocalizationManager.translate('applied')
                            : LocalizationManager.translate('apply'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
