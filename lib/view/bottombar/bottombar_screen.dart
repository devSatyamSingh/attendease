import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../widget/animated_exit_dialog.dart';
import '../../widget/app_colors.dart';
import '../../widget/lazy_indexed_stack.dart';
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
        body: LazyIndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    // Language badalte hi labels dobara build hon
    context.locale;

    // Tab order Urdu me bhi wahi rahe (Home pehle), isliye nav bar ko LTR me rakha hai
    return Directionality(
      textDirection: TextDirection.ltr,
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.whiteColor,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.placeholderColor,
        showUnselectedLabels: true,
        elevation: 10,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: 'nav.home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            label: 'nav.history'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.free_cancellation),
            label: 'nav.leaves'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_rounded),
            label: 'nav.profile'.tr(),
          ),
        ],
      ),
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