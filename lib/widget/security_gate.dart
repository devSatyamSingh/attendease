import 'dart:async';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/device_security_service.dart';
import '../viewmodel/device_security_viewmodel.dart';
import 'app_colors.dart';
import 'app_text.dart';


class SecurityGate extends ConsumerStatefulWidget {
  final Widget child;
  const SecurityGate({super.key, required this.child});

  @override
  ConsumerState<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends ConsumerState<SecurityGate>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _rechecking = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _recheck());
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recheck();
  }

  Future<void> _recheck({bool showSpinner = false}) async {
    if (!mounted) return;
    if (showSpinner) setState(() => _rechecking = true);
    await ref.read(deviceSecurityProvider.notifier).recheck();
    if (mounted && showSpinner) setState(() => _rechecking = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(deviceSecurityProvider, (_, next) {
      final r = next.value;
      final isBlocked = r != null && !r.isSafe;
      if (isBlocked && !_pulse.isAnimating) {
        _pulse.repeat(reverse: true);
      } else if (!isBlocked && _pulse.isAnimating) {
        _pulse.stop();
      }
    });

    final security = ref.watch(deviceSecurityProvider).value;
    final bool blocked = security != null && !security.isSafe;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: widget.child),
        blocked
            ? Positioned.fill(child: _buildBlockScreen(security))
            : const SizedBox.shrink(),
      ],
    );
  }

  // ==================== BLOCK SCREEN ====================
  Widget _buildBlockScreen(DeviceSecurityResult security) {
    final bool mock = security.isMockLocation;

    final String title = mock
        ? "Fake location detected"
        : (security.isRooted ? "Unsafe device detected" : "Emulator detected");

    final IconData icon = mock
        ? Icons.location_off_rounded
        : (security.isRooted ? Icons.gpp_bad_rounded : Icons.phonelink_erase_rounded);

    return Material(
      color: AppColors.scaffoldBgColor,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, .45],
            colors: [
              AppColors.errorColor.withOpacity(.08),
              AppColors.scaffoldBgColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHero(icon),
                    const SizedBox(height: 18),
                    _buildPill(),
                    const SizedBox(height: 14),
                    HeadlineText(title, fontSize: 22, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    AppText(
                      security.message,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.labelTextColor,
                      textAlign: TextAlign.center,
                      height: 1.5,
                    ),
                    const SizedBox(height: 24),
                    mock ? _buildStepsCard() : _buildUnsupportedCard(security),
                    const SizedBox(height: 24),
                    _buildPrimaryButton(),
                    if (mock) ...[
                      const SizedBox(height: 12),
                      _buildSecondaryButton(),
                    ],
                    const SizedBox(height: 18),
                    CaptionText(
                      "We re-check automatically. The app unlocks as soon as this is fixed.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Hero (pulsing rings + icon) ----------
  Widget _buildHero(IconData icon) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return SizedBox(
          height: 150,
          width: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.92 + 0.12 * t,
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.errorColor.withOpacity(.07),
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.95 + 0.08 * t,
                child: Container(
                  height: 112,
                  width: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.errorColor.withOpacity(.13),
                  ),
                ),
              ),
              Container(
                height: 78,
                width: 78,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF87171), Color(0xFFDC2626)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.errorColor.withOpacity(.4),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.whiteColor, size: 36),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.errorColor),
          const SizedBox(width: 6),
          AppText(
            "Attendance access blocked",
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.errorColor,
          ),
        ],
      ),
    );
  }

  // ---------- Steps card (mock GPS) ----------
  Widget _buildStepsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 30,
                width: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.build_circle_outlined, size: 17, color: AppColors.primaryColor),
              ),
              const SizedBox(width: 10),
              AppText("How to fix it", fontSize: 14, fontWeight: FontWeight.w600),
            ],
          ),
          const SizedBox(height: 16),
          _step(1, "Close or uninstall the fake GPS / mock location app.", showLine: true),
          _step(
            2,
            "Go to Developer options > Select mock location app > choose \"Nothing\".",
            showLine: true,
          ),
          _step(3, "Come back here and tap Recheck.", showLine: false),
        ],
      ),
    );
  }

  Widget _step(int n, String text, {required bool showLine}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                height: 24,
                width: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: AppText(
                  "$n",
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteColor,
                ),
              ),
              if (showLine)
                Expanded(
                  child: Container(width: 2, color: AppColors.primaryLight),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? 16 : 0, top: 2),
              child: AppText(
                text,
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppColors.bodyTextColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Card for root / emulator ----------
  Widget _buildUnsupportedCard(DeviceSecurityResult security) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 30,
            width: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.warningColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.info_outline_rounded, size: 17, color: AppColors.warningColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppText(
              security.isRooted
                  ? "Attendance can't be marked from a rooted device. Please use a standard, unmodified phone."
                  : "Attendance can't be marked from an emulator. Please use a real phone.",
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColors.bodyTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.cardBgColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.borderColor),
      boxShadow: [
        BoxShadow(
          color: AppColors.blackColor.withOpacity(.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // ---------- Buttons ----------
  Widget _buildPrimaryButton() {
    final bool disabled = _rechecking;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: disabled ? null : AppColors.primaryGradient,
          color: disabled ? AppColors.disabledColor : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled
              ? []
              : [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: disabled ? null : () => _recheck(showSpinner: true),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Center(
              child: _rechecking
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.whiteColor,
                ),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, color: AppColors.whiteColor, size: 20),
                  const SizedBox(width: 8),
                  AppText(
                    "Recheck",
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.whiteColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => AppSettings.openAppSettings(type: AppSettingsType.developer),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          side: const BorderSide(color: AppColors.borderColor),
          backgroundColor: AppColors.cardBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.developer_mode_rounded, size: 19),
        label: AppText(
          "Open Developer options",
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}