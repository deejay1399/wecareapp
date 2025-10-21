import 'package:flutter/material.dart';
import '../../models/helper.dart';
import '../../models/rating_statistics.dart';
import '../../services/session_service.dart';
import '../../services/helper_auth_service.dart';
import '../../services/rating_service.dart';
import '../../widgets/rating/rating_summary.dart';
import '../../widgets/ui/profile_picture_widget.dart';
import '../role_selection_screen.dart';
import '../rating/user_ratings_screen.dart';
import 'edit_helper_profile_screen.dart';
import 'helper_subscription_screen.dart';
import '../../localization_manager.dart';

class HelperProfileScreen extends StatefulWidget {
  const HelperProfileScreen({super.key});

  @override
  State<HelperProfileScreen> createState() => _HelperProfileScreenState();
}

class _HelperProfileScreenState extends State<HelperProfileScreen> {
  final _ratingService = RatingService();
  Helper? _currentHelper;
  RatingStatistics? _ratingStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentHelper();
  }

  Future<void> _loadCurrentHelper() async {
    try {
      final helper = await SessionService.getCurrentHelper();
      if (helper != null) {
        // Fetch fresh data from database
        final userId = await SessionService.getCurrentUserId();
        if (userId != null) {
          final freshHelper = await HelperAuthService.getHelperById(userId);
          if (freshHelper != null) {
            // Update session with fresh data
            await SessionService.updateCurrentUser(freshHelper.toMap());
          }
          final finalHelper = freshHelper ?? helper;

          // Load rating statistics
          final stats = await _ratingService.getUserRatingStatistics(
            finalHelper.id,
            LocalizationManager.translate('helper'),
          );

          if (mounted) {
            setState(() {
              _currentHelper = finalHelper;
              _ratingStats = stats;
              _isLoading = false;
            });
          }
        } else {
          // Load rating statistics for cached helper
          final stats = await _ratingService.getUserRatingStatistics(
            helper.id,
            LocalizationManager.translate('helper'),
          );

          if (mounted) {
            setState(() {
              _currentHelper = helper;
              _ratingStats = stats;
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
    if (_currentHelper == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHelperProfileScreen(helper: _currentHelper!),
      ),
    );

    // If changes were saved, refresh the profile
    if (result == true) {
      _loadCurrentHelper();
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
              style: TextStyle(color: Colors.red),
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
          child: CircularProgressIndicator(color: Color(0xFFFF8A50)),
        ),
      );
    }

    if (_currentHelper == null) {
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
                style: TextStyle(fontSize: 18, color: Colors.grey),
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
          onRefresh: _loadCurrentHelper,
          color: const Color(0xFFFF8A50),
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
                    color: const Color(0xFFFF8A50),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8A50).withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      LargeProfilePictureWidget(
                        profilePictureBase64:
                            _currentHelper!.profilePictureBase64,
                        fullName: _currentHelper!.fullName,
                        onTap: _navigateToEditProfile,
                        showEditIcon: true,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentHelper!.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LocalizationManager.translate('helper'),
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
                      _currentHelper!.firstName,
                    ),
                    _buildInfoRow(
                      LocalizationManager.translate('last_name'),
                      _currentHelper!.lastName,
                    ),
                    // _buildInfoRow(
                    //   LocalizationManager.translate('birth_date'),
                    //   _currentHelper!.barangay,
                    // ),
                    _buildInfoRow(
                      LocalizationManager.translate('age'),
                      '${_currentHelper!.age} years old',
                    ),
                    _buildInfoRow(
                      LocalizationManager.translate('email'),
                      _currentHelper!.email,
                    ),
                    _buildInfoRow(
                      LocalizationManager.translate('phone'),
                      _currentHelper!.phone,
                    ),
                    _buildInfoRow(
                      LocalizationManager.translate('barangay'),
                      _currentHelper!.barangay,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Skills & Experience Information
                _buildInfoSection(
                  LocalizationManager.translate('skills_experience'),
                  [
                    _buildInfoRow(
                      LocalizationManager.translate('primary_skill'),
                      _currentHelper!.skill,
                    ),
                    _buildInfoRow(
                      LocalizationManager.translate('experience_level'),
                      _currentHelper!.experience,
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
                      _formatDate(_currentHelper!.createdAt),
                    ),
                    _buildInfoRow(
                      LocalizationManager.translate('last_updated'),
                      _formatDate(_currentHelper!.updatedAt),
                    ),
                    _buildInfoRow(
                      LocalizationManager.translate('verification_status'),
                      _currentHelper!.isVerified
                          ? LocalizationManager.translate('verified')
                          : LocalizationManager.translate('pending'),
                      valueColor: _currentHelper!.isVerified
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Rating Statistics
                if (_ratingStats != null) ...[
                  Container(
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                LocalizationManager.translate(
                                  'my_ratings_reviews',
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF8A50),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserRatingsScreen(
                                      userId: _currentHelper!.id,
                                      userType: 'helper',
                                      userName: _currentHelper!.fullName,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                LocalizationManager.translate('view_all'),
                                style: TextStyle(
                                  color: Color(0xFFFF8A50),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RatingSummary(
                          statistics: _ratingStats!,
                          showDistribution: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF8A50),
                          side: const BorderSide(
                            color: Color(0xFFFF8A50),
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
                                  const HelperSubscriptionScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.credit_card),
                        label: Text(
                          LocalizationManager.translate('manage_subscription'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A50),
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
                          style: TextStyle(
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
              color: Color(0xFFFF8A50),
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
