import 'package:flutter/material.dart';
import '../../models/application.dart';
import '../../models/helper.dart';
import '../../services/application_service.dart';
import '../../services/session_service.dart';
import '../../widgets/cards/helper_application_status_card.dart';
import 'helper_application_details_screen.dart';
import '../../localization_manager.dart';

class HelperMyApplicationsScreen extends StatefulWidget {
  const HelperMyApplicationsScreen({super.key});

  @override
  State<HelperMyApplicationsScreen> createState() =>
      _HelperMyApplicationsScreenState();
}

class _HelperMyApplicationsScreenState
    extends State<HelperMyApplicationsScreen> {
  List<Application> _applications = [];
  String _selectedFilter = 'all'; // 'all', 'pending', 'accepted', 'rejected'
  bool _isLoading = true;
  String? _errorMessage;
  Helper? _currentHelper;

  @override
  void initState() {
    super.initState();
    _loadCurrentHelper();
  }

  Future<void> _loadCurrentHelper() async {
    try {
      final helper = await SessionService.getCurrentHelper();
      if (helper != null) {
        setState(() {
          _currentHelper = helper;
        });
        await _loadApplications();
      }
    } catch (e) {
      setState(() {
        _errorMessage = LocalizationManager.translate(
          'failed_to_load_helper_information',
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _loadApplications() async {
    if (_currentHelper == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final applications = await ApplicationService.getApplicationsByHelper(
        _currentHelper!.id,
      );

      if (mounted) {
        setState(() {
          _applications = applications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              '${LocalizationManager.translate('failed_to_load_applications')}: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onApplicationTap(Application application) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HelperApplicationDetailsScreen(application: application),
      ),
    );

    // If application was updated (withdrawn), refresh the list
    if (result != null) {
      _loadApplications();
    }
  }

  Future<void> _onWithdrawApplication(Application application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocalizationManager.translate('withdraw_application')),
          content: Text(
            '${LocalizationManager.translate('withdraw_confirmation')} "${application.jobTitle}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(LocalizationManager.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF44336),
              ),
              child: Text(LocalizationManager.translate('withdraw')),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ApplicationService.withdrawApplication(application.id);
        await _loadApplications(); // Refresh the list

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationManager.translate(
                  'application_withdrawn_successfully',
                ),
              ),
              backgroundColor: const Color(0xFF6B7280),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${LocalizationManager.translate('failed_to_withdraw_application')} $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<Application> get _filteredApplications {
    if (_selectedFilter == 'all') return _applications;
    return _applications.where((app) => app.status == _selectedFilter).toList();
  }

  int get _pendingCount => _applications.where((app) => app.isPending).length;
  int get _acceptedCount => _applications.where((app) => app.isAccepted).length;
  int get _rejectedCount => _applications.where((app) => app.isRejected).length;

  Widget _buildFilterChip(String filter, String label, int count) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF8A50)
              : const Color(0xFFFF8A50).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(
              0xFFFF8A50,
            ).withValues(alpha: isSelected ? 1.0 : 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFFFF8A50),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFFF8A50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFFFF8A50),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFF8A50).withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 60,
                color: Color(0xFFFF8A50),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              LocalizationManager.translate('no_applications_yet'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                LocalizationManager.translate('start_applying_to_jobs'),
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            // Benefits list
            Column(
              children: [
                _buildBenefitItem(
                  Icons.schedule,
                  LocalizationManager.translate('track_application_status'),
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  Icons.message_outlined,
                  LocalizationManager.translate(
                    'receive_messages_from_employers',
                  ),
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  Icons.history,
                  LocalizationManager.translate('view_application_history'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: const Color(0xFFFF8A50)),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF8A50)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                LocalizationManager.translate('error_loading_applications'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadApplications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(LocalizationManager.translate('retry')),
              ),
            ],
          ),
        ),
      );
    }

    final filteredApplications = _filteredApplications;

    if (_applications.isEmpty) {
      return _buildEmptyState();
    }

    if (filteredApplications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '${LocalizationManager.translate('no')} $_selectedFilter ${LocalizationManager.translate('applications')}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: const Color(0xFFFF8A50),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: filteredApplications.length,
        itemBuilder: (context, index) {
          return HelperApplicationStatusCard(
            application: filteredApplications[index],
            onTap: () => _onApplicationTap(filteredApplications[index]),
            onWithdraw: filteredApplications[index].isPending
                ? () => _onWithdrawApplication(filteredApplications[index])
                : null,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      LocalizationManager.translate('my_applications'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8A50),
                      ),
                    ),
                  ),
                  if (_applications.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF8A50).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_applications.length} ${LocalizationManager.translate('total')}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF8A50),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Filter chips
            if (_applications.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip(
                      'all',
                      LocalizationManager.translate('all'),
                      _applications.length,
                    ),
                    const SizedBox(width: 12),
                    _buildFilterChip(
                      'pending',
                      LocalizationManager.translate('under_review'),
                      _pendingCount,
                    ),
                    const SizedBox(width: 12),
                    _buildFilterChip(
                      'accepted',
                      LocalizationManager.translate('accepted'),
                      _acceptedCount,
                    ),
                    const SizedBox(width: 12),
                    _buildFilterChip(
                      'rejected',
                      LocalizationManager.translate('not_selected'),
                      _rejectedCount,
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }
}
