import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_button.dart';
import 'app_colors.dart';
import 'app_text.dart';


class AnimatedExitDialog extends StatelessWidget {
  const AnimatedExitDialog({super.key});

  /// Shows the animated dialog and exits the app if the user confirms.
  static Future<void> show(BuildContext context) async {
    final bool? shouldExit = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Exit App',
      barrierColor: AppColors.blackColor.withOpacity(.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const AnimatedExitDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );

    if (shouldExit == true) {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else {
        exit(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: AppColors.errorColor.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.errorColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            const AppText(
              "Exit AttendEase?",
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 8),
            const AppText(
              "Are you sure you want to close the app?",
              fontSize: 13,
              color: AppColors.labelTextColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: "Cancel",
                    outlined: true,
                    height: 46,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: "Exit",
                    height: 46,
                    color: AppColors.errorColor,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}