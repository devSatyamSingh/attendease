import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AttendEase — reusable primary button.
/// Used for: Login, Check-In/Check-Out, Submit Leave, Submit Device
/// Change Request, Export Report, etc.
///
/// Two distinct "off" states are supported, and they look different
/// on purpose:
/// - disabled  -> onTap is null (e.g. outside geofence, form invalid,
///                already checked in). Button turns solid gray.
/// - loading   -> an API call is in flight. Button keeps its real
///                color/gradient but shows a spinner and blocks taps.
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;

  final double? height;
  final double? width;

  final double? fontSize;
  final Color? textColor;
  final Color? color;
  final Color? disabledColor;
  final Color? disabledTextColor;

  final Gradient? gradient;

  final FontWeight? fontWeight;

  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  final BorderRadiusGeometry? borderRadius;

  final List<BoxShadow>? boxShadow;

  final Widget? child;

  final bool loading;

  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;

  final bool outlined;
  final Color? borderColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onTap,
    this.height,
    this.width,
    this.fontSize,
    this.textColor,
    this.color,
    this.disabledColor,
    this.disabledTextColor,
    this.gradient,
    this.fontWeight,
    this.margin,
    this.padding,
    this.borderRadius,
    this.boxShadow,
    this.child,
    this.loading = false,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.outlined = false,
    this.borderColor,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  bool get _isDisabled => widget.onTap == null;
  bool get _isInteractionBlocked => widget.loading || _isDisabled;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isInteractionBlocked) return;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isInteractionBlocked) return;
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (_isInteractionBlocked) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final Color resolvedFillColor = _isDisabled
        ? (widget.disabledColor ?? AppColors.disabledColor)
        : (widget.color ?? AppColors.primaryColor);

    final Color resolvedTextColor = _isDisabled
        ? (widget.disabledTextColor ?? AppColors.disabledTextColor)
        : (widget.textColor ??
        (widget.outlined ? AppColors.primaryColor : AppColors.whiteColor));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _isInteractionBlocked ? null : widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          alignment: Alignment.center,
          margin: widget.margin,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 14),
          height: widget.height ?? 54,
          width: widget.width ?? screenWidth,
          decoration: BoxDecoration(
            color: widget.outlined
                ? AppColors.whiteColor
                : (widget.gradient == null || _isDisabled
                ? resolvedFillColor
                : null),
            gradient: (widget.outlined || _isDisabled) ? null : widget.gradient,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            border: widget.outlined
                ? Border.all(
              color: _isDisabled
                  ? AppColors.disabledColor
                  : (widget.borderColor ?? AppColors.primaryColor),
              width: 1.4,
            )
                : null,
            boxShadow: (widget.outlined || _isDisabled)
                ? null
                : (widget.boxShadow ??
                [
                  BoxShadow(
                    color: (widget.color ?? AppColors.primaryColor)
                        .withOpacity(.25),
                    blurRadius: 7,
                    offset: const Offset(0, 4),
                  ),
                ]),
          ),
          child: widget.loading
              ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              color: widget.outlined
                  ? AppColors.primaryColor
                  : AppColors.whiteColor,
              strokeWidth: 2.5,
            ),
          )
              : widget.child ??
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.iconColor ?? resolvedTextColor,
                      size: widget.iconSize ?? 20,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      widget.text,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.fontSize ?? 16,
                        color: resolvedTextColor,
                        fontWeight: widget.fontWeight ?? FontWeight.w600,
                        fontFamily: "Poppins",
                        letterSpacing: .3,
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}