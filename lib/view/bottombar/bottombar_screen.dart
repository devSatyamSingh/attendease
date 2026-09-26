import 'package:flutter/material.dart';

import '../../widget/animated_exit_dialog.dart';
import '../../widget/app_colors.dart';
import '../attendance/history_screen.dart';
import '../home/dashboard_screen.dart';
import '../leave/leave_balance_screen.dart';
import '../profile/profile_screen.dart';

class BottomBarScreen extends StatefulWidget {
  const BottomBarScreen({super.key});

  @override
  State<BottomBarScreen> createState() => _BottomBarScreenState();
}

class _BottomBarScreenState extends State<BottomBarScreen> {
  static const int _homeTabIndex = 0;
  int _currentIndex = _homeTabIndex;
  final List<Widget> _tabs = const [
    DashboardScreen(),
    AttendanceHistoryScreen(),
    LeavesScreen(),
    ProfileScreen(),
  ];

  Future<void> _handleBackPress() async {
    if (_currentIndex != _homeTabIndex) {
      setState(() => _currentIndex = _homeTabIndex);
      return;
    }
    await AnimatedExitDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.whiteColor,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.placeholderColor,
      showUnselectedLabels: true,
      elevation: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          label: "History",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.free_cancellation),
          label: "Leaves",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          label: "Profile",
        ),
      ],
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.placeholderColor),
            const SizedBox(height: 12),
            Text(
              "$title screen coming soon",
              style: const TextStyle(color: AppColors.labelTextColor),
            ),
          ],
        ),
      ),
    );
  }
}