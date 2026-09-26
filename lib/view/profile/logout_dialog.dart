import 'package:flutter/material.dart';
import '../../widget/app_button.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';


/// A reusable animated confirmation dialog with a scale + fade entrance,
/// matching the look of the old AnimatedExitDialog but fully configurable
/// so it can be used for Exit, Sign Out, Delete, etc.
class AnimatedConfirmDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String cancelText;
  final String confirmText;
  final Color confirmColor;

  const AnimatedConfirmDialog({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.cancelText = "Cancel",
    required this.confirmText,
    required this.confirmColor,
  });

  /// Shows the animated dialog and returns true if the user confirmed,
  /// false/null if they cancelled or dismissed it.
  static Future<bool?> show(
      BuildContext context, {
        required IconData icon,
        Color iconColor = AppColors.errorColor,
        required String title,
        required String message,
        String cancelText = "Cancel",
        required String confirmText,
        Color confirmColor = AppColors.errorColor,
      }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: AppColors.blackColor.withOpacity(.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => AnimatedConfirmDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        message: message,
        cancelText: cancelText,
        confirmText: confirmText,
        confirmColor: confirmColor,
      ),
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
                color: iconColor.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 18),
            AppText(title, fontSize: 17, fontWeight: FontWeight.w600),
            const SizedBox(height: 8),
            AppText(
              message,
              fontSize: 13,
              color: AppColors.labelTextColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: cancelText,
                    outlined: true,
                    height: 46,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: confirmText,
                    height: 46,
                    color: confirmColor,
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