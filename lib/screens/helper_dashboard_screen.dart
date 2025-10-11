import 'package:flutter/material.dart';
import 'helper/helper_home_screen.dart';
import 'helper/helper_find_jobs_screen.dart';
import 'helper/helper_my_applications_screen.dart';
import 'helper/helper_profile_screen.dart';
import '../widgets/navigation/helper_bottom_nav.dart';

class HelperDashboardScreen extends StatefulWidget {
  const HelperDashboardScreen({super.key});

  @override
  State<HelperDashboardScreen> createState() => _HelperDashboardScreenState();
}

class _HelperDashboardScreenState extends State<HelperDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HelperHomeScreen(),
    HelperFindJobsScreen(),
    HelperMyApplicationsScreen(),
    HelperProfileScreen(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: HelperBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
