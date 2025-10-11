import 'package:flutter/material.dart';
import '../../models/job_posting.dart';
import '../../models/helper_service_posting.dart';
import '../../services/subscription_service.dart';
import '../../services/database_messaging_service.dart';
import '../../services/job_posting_service.dart';
import '../../services/helper_service_posting_service.dart';
import '../../services/session_service.dart';
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

class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({super.key});

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  Map<String, dynamic>? _subscriptionStatus;
  int _unreadMessageCount = 0;
  List<JobPosting> _recentJobPostings = [];
  List<HelperServicePosting> _availableServices = [];
  bool _isLoadingJobs = true;
  bool _isLoadingServices = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSubscriptionStatus(),
      _loadUnreadMessageCount(),
      _loadRecentJobPostings(),
      _loadAvailableServices(),
    ]);
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final status = await SubscriptionService.getCurrentUserSubscriptionStatus();
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
        final allJobPostings = await JobPostingService.getJobPostingsByEmployer(employer.id);
        
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
      final allServices = await HelperServicePostingService.getActiveServicePostings();
      
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
      MaterialPageRoute(
        builder: (context) => const ConversationsScreen(),
      ),
    ).then((_) {
      // Refresh unread count when returning
      _loadUnreadMessageCount();
    });
    
    // Also schedule a short delayed refresh to catch async updates
    Future.delayed(const Duration(milliseconds: 400), _loadUnreadMessageCount);
  }

  void _onCompletedJobsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompletedJobsScreen(),
      ),
    );
  }

  void _onPostJob(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostJobScreen(),
      ),
    );

    if (!context.mounted) return;
    
    // If job was posted successfully, refresh data and show success message
    if (result == true) {
      _loadRecentJobPostings(); // Refresh job postings
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job posted successfully! Check "My Jobs" to view it.'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 3),
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
      MaterialPageRoute(
        builder: (context) => const AllServicesScreen(),
      ),
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
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good ${_getGreeting()}!',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Find the perfect help',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Color(0xFF1565C0),
                                size: 24,
                              ),
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

                // Post Job Button
                PostJobButton(
                  onPressed: () => _onPostJob(context),
                ),

                const SizedBox(height: 24),

                // Quick Actions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SectionHeader(
                    title: 'Quick Actions',
                    subtitle: 'Manage your employer account',
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
                          'Messages',
                          'Chat with helpers',
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
                          'Completed Jobs',
                          'Rate your hires',
                          Icons.history_outlined,
                          const Color(0xFF10B981),
                          _onCompletedJobsTap,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          'Services',
                          'Browse helpers',
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
                    title: 'Recent Job Postings',
                    subtitle: 'Manage your active job listings',
                    onSeeAll: _recentJobPostings.length >= 3 ? () {
                      // Navigate to the My Jobs tab (index 1 in the bottom navigation)
                      if (context.mounted) {
                        DefaultTabController.of(context).animateTo(1);
                      }
                    } : null,
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
                    title: 'Available Services',
                    subtitle: 'Browse helpers by service type',
                    onSeeAll: _availableServices.isNotEmpty ? _onSeeAllServices : null,
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
          const Text(
            'No Job Postings Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start by posting your first job to find the perfect helper',
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
          const Text(
            'No Services Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Helper services will be displayed here once they become available',
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
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
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
                    child: Icon(
                      icon,
                      size: 24,
                      color: color,
                    ),
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
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
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
