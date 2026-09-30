import 'package:flutter/material.dart';

extension DirectionX on BuildContext {
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}

/// Back button: LTR me ←, RTL me →
class AppBackButton extends StatelessWidget {
  final Color? color;
  final double size;
  final VoidCallback? onPressed;

  const AppBackButton({super.key, this.color, this.size = 22, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: Icon(
        context.isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
        size: size,
        color: color,
        // Auto-mirroring band, hum direction khud choose kar rahe hain
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

/// Chevron / forward arrow: LTR me >, RTL me <
class DirIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const DirIcon({super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(
      context.isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      size: size,
      color: color,
      textDirection: TextDirection.ltr,
    );
  }
}