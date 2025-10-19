import 'package:flutter/material.dart';
import '../../models/employer.dart';
import '../../services/session_service.dart';
import '../../services/employer_auth_service.dart';
import '../../widgets/ui/profile_picture_widget.dart';
import '../role_selection_screen.dart';
import 'edit_employer_profile_screen.dart';
import 'employer_subscription_screen.dart';
import '../../localization_manager.dart';

class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key});

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  Employer? _currentEmployer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmployer();
  }

  Future<void> _loadCurrentEmployer() async {
    try {
      final employer = await SessionService.getCurrentEmployer();
      if (employer != null) {
        // Fetch fresh data from database
        final userId = await SessionService.getCurrentUserId();
        if (userId != null) {
          final freshEmployer = await EmployerAuthService.getEmployerById(
            userId,
          );
          if (freshEmployer != null) {
            // Update session with fresh data
            await SessionService.updateCurrentUser(freshEmployer.toMap());
          }
          if (mounted) {
            setState(() {
              _currentEmployer = freshEmployer ?? employer;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _currentEmployer = employer;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_currentEmployer == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditEmployerProfileScreen(employer: _currentEmployer!),
      ),
    );

    // If changes were saved, refresh the profile
    if (result == true) {
      _loadCurrentEmployer();
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocalizationManager.translate('logout')),
        content: Text(
          LocalizationManager.translate('are_you_sure_you_want_to_logout'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocalizationManager.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await SessionService.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
            child: Text(
              LocalizationManager.translate('logout'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1565C0)),
        ),
      );
    }

    if (_currentEmployer == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                LocalizationManager.translate('unable_to_load_profile'),
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(LocalizationManager.translate('logout')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCurrentEmployer,
          color: const Color(0xFF1565C0),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      LargeProfilePictureWidget(
                        profilePictureBase64:
                            _currentEmployer!.profilePictureBase64,
                        fullName: _currentEmployer!.fullName,
                        onTap: _navigateToEditProfile,
                        showEditIcon: true,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentEmployer!.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LocalizationManager.translate('employer'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Profile Information
                _buildInfoSection(
                  LocalizationManager.translate('personal_information'),
                  [
                    _buildInfoRow(
                      LocalizationManager.translate('first_name'),
                      _currentEmployer!.firstName ?? '',
                    ),
                    _buildInfoRow(
                      LocalizationManager.translate('last_name'),
                      _currentEmployer!.lastName ?? '',
                    ),
                    _buildInfoRow(
                      LocalizationManager.translate('age'),
                      '${_currentEmployer!.age ?? 0} ${LocalizationManager.translate('years_old')}',
                    ),
                    _buildInfoRow(
                      LocalizationManager.translate('email'),
                      _currentEmployer!.email ?? '',
                    ),
                    _buildInfoRow(
                      LocalizationManager.translate('phone'),
                      _currentEmployer!.phone ?? '',
                    ),
                    _buildInfoRow(
                      LocalizationManager.translate('barangay'),
                      _currentEmployer!.barangay ?? '',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Account Information
                _buildInfoSection(
                  LocalizationManager.translate('account_information'),
                  [
                    _buildInfoRow(
                      LocalizationManager.translate('member_since'),
                      _formatDate(_currentEmployer!.createdAt),
                    ),
                    _buildInfoRow(
                      LocalizationManager.translate('last_updated'),
                      _formatDate(_currentEmployer!.updatedAt),
                    ),
                    _buildInfoRow(
                      LocalizationManager.translate('verification_status'),
                      _currentEmployer!.isVerified == true
                          ? LocalizationManager.translate('verified')
                          : LocalizationManager.translate('pending'),
                      valueColor: _currentEmployer!.isVerified == true
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _navigateToEditProfile,
                        icon: const Icon(Icons.edit),
                        label: Text(
                          LocalizationManager.translate('edit_profile'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1565C0),
                          side: const BorderSide(
                            color: Color(0xFF1565C0),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EmployerSubscriptionScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.credit_card),
                        label: Text(
                          LocalizationManager.translate('manage_subscription'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: Text(
                          LocalizationManager.translate('logout'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
