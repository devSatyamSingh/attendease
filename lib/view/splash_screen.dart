import 'dart:async';
import 'package:flutter/material.dart';
import '../widget/app_colors.dart';
import '../widget/app_text.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _splashDuration = Duration(seconds: 5);

  Timer? _colorTimer;

  final List<Color> _loaderColors = [
    AppColors.secondaryColor,
    AppColors.workingColor,
    AppColors.primaryColor,
    Colors.orangeAccent,
    Colors.purpleAccent,
  ];

  int _colorIndex = 0;

  @override
  void initState() {
    super.initState();
    _colorTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) return;
      setState(() {
        _colorIndex = (_colorIndex + 1) % _loaderColors.length;
      });
    });
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(_splashDuration);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void dispose() {
    _colorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final iconSize = size.width * 0.32 > 140 ? 140.0 : size.width * 0.32;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 4),

                    _BrandIcon(size: iconSize),

                    const SizedBox(height: 26),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          "AttendEase",
                          fontSize: size.width * 0.09 > 34
                              ? 34
                              : size.width * 0.09,
                          fontWeight: FontWeight.w800,
                          color: AppColors.whiteColor,
                        ),

                        const SizedBox(width: 6),

                        Container(
                          height: 8,
                          width: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    AppText(
                      "SMART EMPLOYEE ATTENDANCE",
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.2,
                      color: AppColors.whiteColor.withOpacity(.75),
                    ),
                    const Spacer(flex: 3),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: SizedBox(
                        key: ValueKey(_colorIndex),
                        height: 34,
                        width: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _loaderColors[_colorIndex],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _AnimatedProgressTrack(duration: _splashDuration),
                    const Spacer(flex: 4),
                    const _ProtocolBadge(),
                    const SizedBox(height: 14),
                    AppText(
                      "AttendEase Enterprise Edition • v2.4.0",
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.whiteColor.withOpacity(.85),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      "Secured with Hardware-Backed Biometrics & Geofencing",
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.whiteColor.withOpacity(.55),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  final double size;
  final bool showStatusDot;
  const _BrandIcon({required this.size, this.showStatusDot = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor.withOpacity(.9),
                AppColors.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.26),
            border: Border.all(color: AppColors.whiteColor.withOpacity(.25)),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackColor.withOpacity(.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.watch_later_rounded,
            color: AppColors.whiteColor,
            size: size * 0.5,
          ),
        ),
        if (showStatusDot)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              height: 16,
              width: 16,
              decoration: BoxDecoration(
                color: AppColors.workingColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.whiteColor, width: 2.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _AnimatedProgressTrack extends StatelessWidget {
  final Duration duration;
  const _AnimatedProgressTrack({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.blackColor.withOpacity(.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth - 8;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: duration,
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: trackWidth * value),
                  child: child,
                ),
              );
            },
            child: Container(
              height: 8,
              width: 8,
              decoration: const BoxDecoration(
                color: AppColors.workingColor,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProtocolBadge extends StatelessWidget {
  const _ProtocolBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.whiteColor.withOpacity(.3)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: 14, color: AppColors.secondaryColor),
          const SizedBox(width: 8),
          AppText(
            "ZERO-TRUST ENTERPRISE PROTOCOL",
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: AppColors.whiteColor.withOpacity(.9),
          ),
        ],
      ),
    );
  }
}
