import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/forms/email_phone_text_field.dart';
import '../widgets/forms/custom_text_field.dart';
import '../utils/validators/login_validators.dart';
import '../services/employer_auth_service.dart';
import '../services/helper_auth_service.dart';
import '../services/supabase_service.dart';
import '../services/session_service.dart';
import '../services/subscription_service.dart';
import 'employer_register_screen.dart';
import 'helper_register_screen.dart';
import 'employer_dashboard_screen.dart';
import 'helper_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final String userType; // 'Employer' or 'Helper'

  const LoginScreen({super.key, required this.userType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  Color get _themeColor => widget.userType == 'Employer'
      ? const Color(0xFF1565C0)
      : const Color(0xFFFF8A50);

  @override
  void initState() {
    super.initState();
    _loadRememberedData();
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedData() async {
    final isRememberMeEnabled = await SessionService.isRememberMeEnabled();
    final rememberedEmailOrPhone =
        await SessionService.getRememberedEmailOrPhone();

    if (isRememberMeEnabled && rememberedEmailOrPhone != null) {
      setState(() {
        _rememberMe = true;
        _emailPhoneController.text = rememberedEmailOrPhone;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if Supabase is initialized
    if (!SupabaseService.isInitialized) {
      _showErrorMessage(
        'Database connection not available. Please check your configuration.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      if (widget.userType == 'Employer') {
        result = await EmployerAuthService.loginEmployer(
          emailOrPhone: _emailPhoneController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        result = await HelperAuthService.loginHelper(
          emailOrPhone: _emailPhoneController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) return;

      if (result['success']) {
        // Save login session
        final userData = widget.userType == 'Employer'
            ? result['employer'].toMap()
            : result['helper'].toMap();

        await SessionService.saveLoginSession(
          userType: widget.userType,
          userId: userData['id'],
          userData: userData,
          rememberMe: _rememberMe,
          emailOrPhone: _rememberMe ? _emailPhoneController.text.trim() : null,
        );

        // CRITICAL: Force refresh subscription status after login
        // This ensures stale subscription cache won't show "Trial Ended" banner
        // after logout/login cycle
        await SubscriptionService.forceRefreshSubscriptionStatus(
          userData['id'],
        );

        if (!mounted) return;
        // Login successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to appropriate dashboard
        if (widget.userType == 'Employer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const EmployerDashboardScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HelperDashboardScreen(),
            ),
          );
        }
      } else {
        // Login failed
        _showErrorMessage(result['message']);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Login failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _openFacebookAppeal() async {
    const facebookUrl =
        'https://www.facebook.com/profile.php?id=61584711443164';
    try {
      if (await canLaunchUrl(Uri.parse(facebookUrl))) {
        await launchUrl(
          Uri.parse(facebookUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorMessage('Could not open Facebook link');
      }
    } catch (e) {
      _showErrorMessage('Error opening Facebook: $e');
    }
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Forgot password functionality - Coming Soon'),
        backgroundColor: _themeColor,
      ),
    );
  }

  void _navigateToRegister() {
    if (widget.userType == 'Employer') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EmployerRegisterScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HelperRegisterScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom App Bar
              SizedBox(
                height: 80,
                width: double.infinity,
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => Navigator.pop(context),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.arrow_back, color: _themeColor),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Welcome Back',
                          style: TextStyle(
                            color: _themeColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Logo and Welcome Section
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _themeColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/wecarelogo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _themeColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Continue as ${widget.userType}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF546E7A),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 40),

              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Email/Phone Field
                    EmailPhoneTextField(
                      controller: _emailPhoneController,
                      validator: LoginValidators.validateEmailOrPhone,
                      themeColor: _themeColor,
                    ),

                    // Password Field
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      onPasswordToggle: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      validator: LoginValidators.validatePassword,
                    ),

                    // Remember Me & Forgot Password Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Transform.scale(
                              scale: 1.1,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: _themeColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF546E7A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _forgotPassword,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 16,
                              color: _themeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _themeColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: _themeColor.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFE0E0E0),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFE0E0E0),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _navigateToRegister,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _themeColor,
                          side: BorderSide(color: _themeColor, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Create New Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Appeal Account Button (for blocked users)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF8A50),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFFF8A50),
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Account Blocked?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'If your account has been blocked, you can appeal by contacting us on Facebook.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openFacebookAppeal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1877F2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: const Text(
                                'Appeal on Facebook',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
