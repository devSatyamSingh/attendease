import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  static const List<_NavItemData> _items = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      labelKey: 'nav.home',
    ),
    _NavItemData(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_month_rounded,
      labelKey: 'nav.history',
    ),
    _NavItemData(
      icon: Icons.event_available_outlined,
      activeIcon: Icons.event_available_rounded,
      labelKey: 'nav.leaves',
    ),
    _NavItemData(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      labelKey: 'nav.profile',
    ),
  ];

  Future<void> _handleBackPress() async {
    if (_currentIndex != _homeTabIndex) {
      setState(() => _currentIndex = _homeTabIndex);
      return;
    }
    await AnimatedExitDialog.show(context);
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
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
        backgroundColor: AppColors.scaffoldBgColor,
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

    // Tab order Urdu me bhi wahi rahe (Home pehle), isliye nav bar LTR me hai
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackColor.withOpacity(.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                return Expanded(
                  child: _NavButton(
                    data: item,
                    label: item.labelKey.tr(),
                    selected: index == _currentIndex,
                    onTap: () => _onTabSelected(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== NAV ITEM DATA ====================
class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String labelKey;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
  });
}

// ==================== NAV BUTTON ====================
class _NavButton extends StatelessWidget {
  final _NavItemData data;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.data,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
    selected ? AppColors.primaryColor : AppColors.placeholderColor;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primaryColor.withOpacity(.08),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon ke peeche pill jo select hone par phail jata hai
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                height: 32,
                width: selected ? 60 : 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    selected ? data.activeIcon : data.icon,
                    key: ValueKey(selected),
                    size: 22,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}