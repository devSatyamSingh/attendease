import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/routes/route_name.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../widget/app_colors.dart';
import '../widget/app_text.dart';


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _splashDuration = Duration(seconds: 4);
  static const _entranceDuration = Duration(milliseconds: 750);
  static const _pulseDuration = Duration(milliseconds: 1400);

  Timer? _colorTimer;

  final List<Color> _loaderColors = [
    AppColors.secondaryColor,
    AppColors.workingColor,
    AppColors.primaryColor,
    Colors.orangeAccent,
    Colors.purpleAccent,
  ];
  int _colorIndex = 0;

  // Drives the left -> right progress dot; its value IS the progress.
  late final AnimationController _progressController;

  // One-shot entrance (logo + title) pop-in.
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceOpacity;

  // Gentle continuous "breathing" once the logo has landed.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Kick the session check off immediately so it's almost certainly
    // resolved well before the 4s splash duration finishes.
    ref.read(sessionCheckProvider);

    _colorTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) return;
      setState(() => _colorIndex = (_colorIndex + 1) % _loaderColors.length);
    });

    _entranceController = AnimationController(vsync: this, duration: _entranceDuration);
    _entranceScale = CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack);
    _entranceOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, .6, curve: Curves.easeOut),
    );

    _pulseController = AnimationController(vsync: this, duration: _pulseDuration)
      ..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressController = AnimationController(vsync: this, duration: _splashDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _navigateNext();
      });

    _entranceController.forward();
    _progressController.forward();
  }

  Future<void> _navigateNext() async {
    if (!mounted || _navigated) return;
    _navigated = true;

    bool isLoggedIn = false;
    try {
      isLoggedIn = await ref.read(sessionCheckProvider.future);
    } catch (_) {
      isLoggedIn = false; // corrupt/unavailable storage -> safest is Login
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      isLoggedIn ? RouteNames.bottombar : RouteNames.login,
    );
  }

  @override
  void dispose() {
    _colorTimer?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final iconSize = size.width * 0.24 > 100 ? 100.0 : size.width * 0.24;

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
                    _buildAnimatedBrandBlock(size, iconSize),
                    const Spacer(flex: 1),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: SizedBox(
                        key: ValueKey(_colorIndex),
                        height: 34,
                        width: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          valueColor: AlwaysStoppedAnimation<Color>(_loaderColors[_colorIndex]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AnimatedProgressTrack(controller: _progressController),
                    const Spacer(flex: 3),
                    const _ProtocolBadge(),
                    const SizedBox(height: 9),
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

  Widget _buildAnimatedBrandBlock(Size size, double iconSize) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _pulseController]),
      builder: (context, child) {
        final entranceValue = _entranceScale.value.clamp(0.0, 1.4);
        return Opacity(
          opacity: _entranceOpacity.value,
          child: Transform.scale(scale: entranceValue * _pulseScale.value, child: child),
        );
      },
      child: Column(
        children: [
          _BrandIcon(size: iconSize),
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                "AttendEase",
                fontSize: size.width * 0.09 > 34 ? 34 : size.width * 0.09,
                fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  final double size;
  const _BrandIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: AppColors.whiteColor.withOpacity(.6)),
        boxShadow: [
          BoxShadow(color: AppColors.blackColor.withOpacity(.25), blurRadius: 10),
        ],
      ),
      child: Image.asset("assets/icons/icon.png", fit: BoxFit.contain),
    );
  }
}

/// Left -> right progress dot. `controller.value` (0 -> 1) IS the
/// position — no independent timer, so it can never fall out of sync
/// with the splash duration driving it.
class _AnimatedProgressTrack extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedProgressTrack({required this.controller});

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
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: trackWidth * controller.value),
                  child: child,
                ),
              );
            },
            child: Container(
              height: 8,
              width: 8,
              decoration: const BoxDecoration(color: AppColors.workingColor, shape: BoxShape.circle),
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