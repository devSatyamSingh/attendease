import 'package:attendease/view/bottombar/bottombar_screen.dart';
import 'package:flutter/material.dart';

import '../../view/auth/login_screen.dart';
import '../../view/device/device_change_request_screen.dart';
import '../../view/home/dashboard_screen.dart';
import '../../view/leave/leave_balance_screen.dart';
import '../../view/leave/apply_leave_screen.dart';
import '../../view/leave/leave_history_screen.dart';
import '../../view/splash_screen.dart';
import '../../widget/app_colors.dart';

import 'route_name.dart';

class AppRoutes {
  AppRoutes._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return _route(const SplashScreen(), settings);

      case RouteNames.login:
        return _route(const LoginScreen(), settings);

      case RouteNames.dashboard:
        return _route(const DashboardScreen(), settings);

      case RouteNames.bottombar:
        return _route(const BottomBarScreen(), settings);

    // ─── LEAVE MODULE ───
      case RouteNames.leaveBalance:
        return _route(const LeavesScreen(), settings);

      case RouteNames.applyLeave:
        return _route(const ApplyLeaveScreen(), settings);

      case RouteNames.leaveHistory:
        return _route(const LeaveHistoryScreen(), settings);

      case RouteNames.deviceChangeRequest:
        return _route(const DeviceChangeRequestScreen(), settings);

      default:
        return _route(_UnknownRouteScreen(routeName: settings.name), settings);
    }
  }

  static Route<dynamic> _route(Widget screen, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => screen, settings: settings);
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  final String? routeName;

  const _UnknownRouteScreen({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: Center(
        child: Text(
          "No screen registered for route: ${routeName ?? 'unknown'}",
          style: const TextStyle(color: AppColors.errorColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}