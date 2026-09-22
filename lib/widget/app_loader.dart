import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'app_colors.dart';

/// AttendEase — reusable loading indicator.
///
/// Use `AppLoader()` inline (e.g. center of a screen while today's
/// attendance / leave balance loads), or `AppLoader.show(context)` /
/// `AppLoader.hide(context)` as a full-screen blocking overlay while a
/// check-in, check-out, or leave-submit API call is running.
class AppLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppLoader({
    super.key,
    this.size = 32,
    this.color,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppColors.primaryColor,
          ),
        ),
      ),
    );
  }

  /// Blocking full-screen overlay. Call before an API request and
  /// [hide] it in the `finally` block so it always closes even on error.
  ///
  /// Example:
  /// ```dart
  /// AppLoader.show(context, message: "Checking in...");
  /// try {
  ///   await attendanceRepo.checkIn(...);
  /// } finally {
  ///   AppLoader.hide(context);
  /// }
  /// ```
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.blackColor.withOpacity(.25),
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLoader(),
                if (message != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.bodyTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}

/// Shimmer skeleton block — used for history/leave-history/report list
/// loading states instead of a spinner (feels faster, matches list shape).
/// Needs the `shimmer` package (already in pubspec.yaml).
class AppSkeletonBox extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const AppSkeletonBox({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.fieldFillColor,
      highlightColor: AppColors.borderColor,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}