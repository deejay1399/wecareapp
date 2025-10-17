import 'package:flutter/material.dart';
import 'dart:async';
import 'role_selection_screen.dart';
import 'employer_dashboard_screen.dart';
import 'helper_dashboard_screen.dart';
import '../services/session_service.dart';

class SplashScreen extends StatefulWidget {
  final Future<void> Function(String)? onLanguageChanged;

  const SplashScreen({super.key, this.onLanguageChanged});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _statusText = 'Loading...';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _startSplashTimer();
    _animationController.forward();
  }

  void _updateStatus(String status) {
    if (mounted) {
      setState(() {
        _statusText = status;
      });
    }
    debugPrint('🔄 Splash: $status');
  }

  void _startSplashTimer() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _checkAuthAndNavigate();
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      _updateStatus('Checking session...');

      // Check if user is logged in
      final isLoggedIn = await SessionService.isLoggedIn();

      if (isLoggedIn) {
        _updateStatus('Session found! Getting user info...');

        // Get user type to determine which dashboard to show
        final userType = await SessionService.getCurrentUserType();

        debugPrint('🔍 User type found: $userType');

        if (userType == 'Employer') {
          _updateStatus('Welcome back, Employer!');

          // Small delay to show the welcome message
          await Future.delayed(const Duration(milliseconds: 500));

          // Navigate to Employer Dashboard
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const EmployerDashboardScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
        } else if (userType == 'Helper') {
          _updateStatus('Welcome back, Helper!');

          // Small delay to show the welcome message
          await Future.delayed(const Duration(milliseconds: 500));

          // Navigate to Helper Dashboard
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const HelperDashboardScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
        } else {
          // Invalid user type, go to role selection
          debugPrint('⚠️ Invalid user type: $userType');
          _updateStatus('Invalid session. Please login again.');
          await Future.delayed(const Duration(milliseconds: 1000));
          _navigateToRoleSelection();
        }
      } else {
        // User not logged in, go to role selection
        debugPrint('ℹ️ No active session found');
        _updateStatus('No active session');
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToRoleSelection();
      }
    } catch (e) {
      // Error checking session, go to role selection as fallback
      debugPrint('❌ Error checking auth session: $e');
      _updateStatus('Session error. Redirecting...');
      await Future.delayed(const Duration(milliseconds: 1000));
      _navigateToRoleSelection();
    }
  }

  void _navigateToRoleSelection() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const RoleSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFF1565C0).withValues(alpha: 0.05),
              const Color(0xFF1565C0).withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with enhanced shadow and container
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              90,
                            ), // Perfect circle: half of width/height
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF1565C0,
                                ).withValues(alpha: 0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 15,
                                spreadRadius: 0,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Image.asset(
                            'assets/images/wecarelogo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // App title with enhanced styling
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'WeCare',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1565C0),
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: const Color(
                                  0xFF1565C0,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Tagline with better contrast
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value * 0.9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Connecting Care, Creating Opportunities',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF37474F),
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            shadows: [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.8),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 80),

                // Status text with better visibility
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value * 0.85,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFF1565C0,
                            ).withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _statusText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF37474F),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Enhanced progress indicator
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value * 0.8,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF1565C0,
                              ).withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF1565C0),
                            ),
                            backgroundColor: Color(0xFFE3F2FD),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
