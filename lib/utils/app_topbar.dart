import 'package:flutter/material.dart';
import '../widget/app_colors.dart';
import '../widget/app_text.dart';


/// Reusable top bar for every screen.
/// Ek hi jagah se fontSize / fontWeight / height / icon size control hoga.
///
/// Usage:
///   const AppTopBar(title: "My Leaves")
///   const AppTopBar(title: "Profile", color: AppColors.whiteColor)   // gradient/dark bg ke liye
///   AppTopBar(title: "Attendance History", trailing: AppTopBarAction(icon: Icons.calendar_month_rounded, onTap: () {}))
class AppTopBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Title + back icon ka color (white bg / gradient dono ke liye)
  final Color color;

  const AppTopBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
    this.color = AppColors.headlineTextColor,
  });

  // ---- Global design tokens: yahin change karo, poori app me change ho jayega ----
  static const double height = 48;
  static const double sideSlot = 40; // back/trailing ka fixed width
  static const double titleFontSize = 16;
  static const FontWeight titleFontWeight = FontWeight.w600;
  static const double iconSize = 22;

  @override
  Widget build(BuildContext context) {
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
                child: Icon(Icons.arrow_back_rounded, size: iconSize, color: color),
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

/// Top bar ke right side ka icon button (same size/style har jagah).
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