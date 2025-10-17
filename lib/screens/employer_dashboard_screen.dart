import 'package:flutter/material.dart';
import 'employer/employer_home_screen.dart';
import 'employer/employer_my_jobs_screen.dart';
import 'employer/employer_applications_screen.dart';
import 'employer/employer_profile_screen.dart';
import '../widgets/navigation/employer_bottom_nav.dart';
import '../../language_manager.dart';

class EmployerDashboardScreen extends StatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  State<EmployerDashboardScreen> createState() =>
      _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    EmployerHomeScreen(),
    EmployerMyJobsScreen(),
    EmployerApplicationsScreen(),
    EmployerProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Rebuild the dashboard (and its bottom nav) when the language changes
    LanguageManager.selectedLanguageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageManager.selectedLanguageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: EmployerBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
