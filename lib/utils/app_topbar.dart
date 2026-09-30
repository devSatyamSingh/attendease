import 'package:flutter/material.dart';
import '../widget/app_colors.dart';
import '../widget/app_text.dart';

class AppTopBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Color color;

  const AppTopBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
    this.color = AppColors.headlineTextColor,
  });

  // ---- Global design tokens ----
  static const double height = 48;
  static const double sideSlot = 40;
  static const double titleFontSize = 16;
  static const FontWeight titleFontWeight = FontWeight.w600;
  static const double iconSize = 22;

  /// false (recommended): RTL me arrow → dikhega (standard Urdu/Arabic behavior)
  /// true: Urdu me bhi arrow ← hi rahega (sirf position right pe hogi)
  static const bool keepBackArrowLeft = false;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // keepBackArrowLeft = true ho to hamesha ← , warna RTL me →
    final backIcon = (isRtl && !keepBackArrowLeft)
        ? Icons.arrow_forward_rounded
        : Icons.arrow_back_rounded;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(
            width: sideSlot,
            child: showBack
                ? InkWell(
              onTap: onBack ?? () => Navigator.maybePop(context),
              customBorder: const CircleBorder(),
              child: SizedBox(
                height: sideSlot,
                width: sideSlot,
                child: Icon(
                  backIcon,
                  size: iconSize,
                  color: color,
                  // Auto-mirror band: direction hum khud upar choose kar chuke hain
                  textDirection: TextDirection.ltr,
                ),
              ),
            )
                : null,
          ),
          Expanded(
            child: AppText(
              title,
              fontSize: titleFontSize,
              fontWeight: titleFontWeight,
              color: color,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: sideSlot, child: trailing),
        ],
      ),
    );
  }
}

/// Top bar ke trailing side ka icon button.
class AppTopBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const AppTopBarAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = AppColors.headlineTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        height: AppTopBar.sideSlot,
        width: AppTopBar.sideSlot,
        child: Icon(icon, size: AppTopBar.iconSize, color: color),
      ),
    );
  }
}