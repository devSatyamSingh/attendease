import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/connectivity_service.dart';
import '../../widget/app_text.dart';
import '../utils/app_utils.dart';

/// AttendEase — full-screen "Connection Lost" state.
/// Shown by [ConnectivityWrapper] as an overlay whenever the device
/// has no real internet access; disappears automatically the moment
/// connectivity is restored (the wrapper watches the connectivity
/// stream, this screen itself does no navigation).
class NoInternetScreen extends StatefulWidget {
  final VoidCallback onClose;

  const NoInternetScreen({super.key, required this.onClose});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _checking = false;
  final DateTime _offlineSince = DateTime.now();

  static const Color _bgColor = Color(0xFFF3F2FA);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _accentBlue = Color(0xFF3556E8);
  static const Color _accentBlueDark = Color(0xFF3B2FC9);
  static const Color _dangerRed = Color(0xFFE24C4C);
  static const Color _dangerRedBg = Color(0xFFFCE4E4);
  static const Color _successGreen = Color(0xFF1FAE6E);
  static const Color _successGreenBg = Color(0xFFE1F7EC);
  static const Color _headline = Color(0xFF161A2B);
  static const Color _body = Color(0xFF6B7085);
  static const Color _rowBg = Color(0xFFF3F2FA);

  Future<void> _handleRetry() async {
    setState(() => _checking = true);
    final hasInternet = await checkInternetNow();
    if (!mounted) return;
    setState(() => _checking = false);
    if (hasInternet) {
      widget.onClose();
    } else {
      AppUtils.showErrorSnackbar(context, "Still no internet connection.");

    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bgColor,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _buildTopBar(),
                const SizedBox(height: 18),
                _buildStatusRow(),
                const SizedBox(height: 36),
                Center(child: _AnimatedWifiOffIcon()),
                const SizedBox(height: 28),
                const Center(
                  child: AppText("You're Offline", fontSize: 24, fontWeight: FontWeight.w800, color: _headline),
                ),
                const SizedBox(height: 10),
                const AppText(
                  "We couldn't connect to AttendEase servers. Check your "
                      "mobile data or Wi-Fi to sync your attendance logs.",
                  fontSize: 14,
                  color: _body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                _buildOfflineClockInCard(),
                const SizedBox(height: 18),
                _buildDiagnosticsCard(),
                const SizedBox(height: 26),
                _buildRetryButton(),
                const SizedBox(height: 12),
                _buildSettingsButton(),
                const SizedBox(height: 20),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== TOP BAR ====================
  Widget _buildTopBar() {
    return Row(
      children: [
        InkWell(
          onTap: _handleRetry,
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.close_rounded, color: _headline, size: 26),
          ),
        ),
        const Expanded(
          child: AppText("Connection Lost", fontSize: 17, fontWeight: FontWeight.w600, color: _headline, textAlign: TextAlign.center),
        ),
        Container(
          height: 38,
          width: 38,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: _accentBlue, shape: BoxShape.circle),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  // ==================== STATUS ROW ====================
  Widget _buildStatusRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: _dangerRedBg, borderRadius: BorderRadius.circular(20)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: _dangerRed),
              SizedBox(width: 6),
              AppText("OFFLINE MODE", fontSize: 11, fontWeight: FontWeight.w800, color: _dangerRed, letterSpacing: .4),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_outline_rounded, size: 14, color: _body),
            SizedBox(width: 5),
            AppText("Encrypted Local Vault", fontSize: 12, fontWeight: FontWeight.w600, color: _body),
          ],
        ),
      ],
    );
  }

  // ==================== OFFLINE CLOCK-IN CARD ====================
  Widget _buildOfflineClockInCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _successGreenBg, shape: BoxShape.circle),
                child: const Icon(Icons.shield_outlined, color: _successGreen, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText("Offline Clock-In is Active", fontSize: 15, fontWeight: FontWeight.w800, color: _headline),
                    SizedBox(height: 2),
                    AppText("PUNCH PROTECTION ACTIVE", fontSize: 10, fontWeight: FontWeight.w800, color: _successGreen, letterSpacing: .5),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const AppText(
            "Don't worry! Your attendance punches and timestamps are "
                "securely encrypted and cached locally on this device. They "
                "will automatically sync as soon as connectivity is restored.",
            fontSize: 13,
            color: _body,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: _rowBg, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: _accentBlue),
                const SizedBox(width: 8),
                const Expanded(
                  child: AppText("Pending Queue: 1 Punch", fontSize: 13, fontWeight: FontWeight.w600, color: _headline),
                ),
                AppText(DateFormat("hh:mm a").format(_offlineSince), fontSize: 12, fontWeight: FontWeight.w700, color: _body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== QUICK DIAGNOSTICS CARD ====================
  Widget _buildDiagnosticsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              AppText("Quick Diagnostics", fontSize: 16, fontWeight: FontWeight.w800, color: _headline),
              AppText("Live Hardware Scan", fontSize: 11, fontWeight: FontWeight.w600, color: _body),
            ],
          ),
          const SizedBox(height: 14),
          _buildDiagnosticRow(
            icon: Icons.wifi_rounded,
            iconColor: _dangerRed,
            iconBg: _dangerRedBg,
            label: "Wi-Fi Status",
            valueLabel: "Disconnected",
            valueColor: _dangerRed,
            valueBg: _dangerRedBg,
          ),
          const SizedBox(height: 10),
          _buildDiagnosticRow(
            icon: Icons.signal_cellular_alt_rounded,
            iconColor: _body,
            iconBg: _rowBg,
            label: "Cellular Network",
            valueLabel: "No Service",
            valueColor: _body,
            valueBg: _rowBg,
          ),
          // const SizedBox(height: 10),
          // _buildDiagnosticRow(
          //   icon: Icons.verified_user_outlined,
          //   iconColor: _successGreen,
          //   iconBg: _successGreenBg,
          //   label: "Biometric & Vault",
          //   valueLabel: "Armed (AES-256)",
          //   valueColor: _successGreen,
          //   valueBg: _successGreenBg,
          //   valuePrefixIcon: Icons.check_circle_rounded,
          // ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String valueLabel,
    required Color valueColor,
    required Color valueBg,
    IconData? valuePrefixIcon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: _rowBg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppText(label, fontSize: 13, fontWeight: FontWeight.w600, color: _headline),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: valueBg, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (valuePrefixIcon != null) ...[
                  Icon(valuePrefixIcon, size: 13, color: valueColor),
                  const SizedBox(width: 4),
                ],
                AppText(valueLabel, fontSize: 11, fontWeight: FontWeight.w700, color: valueColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUTTONS ====================
  Widget _buildRetryButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: _checking ? null : _handleRetry,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_accentBlue, _accentBlueDark]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: _accentBlue.withOpacity(.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: _checking
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
              : const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              AppText("Try Reconnecting", fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        // Opens the device's network settings — implement via a
        // platform channel or a package like app_settings if desired.
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(color: _rowBg, borderRadius: BorderRadius.circular(30)),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings_outlined, color: _headline, size: 20),
              SizedBox(width: 8),
              AppText("Open Device Settings", fontSize: 16, fontWeight: FontWeight.w700, color: _headline),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== FOOTER ====================
  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.sync_rounded, size: 14, color: _successGreen),
            SizedBox(width: 6),
            AppText("AttendEase Local Cache Engine", fontSize: 12, fontWeight: FontWeight.w700, color: _successGreen),
          ],
        ),
        const SizedBox(height: 4),
        const AppText(
          "Automatic sync every 30s once connectivity returns",
          fontSize: 11,
          color: _body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AnimatedWifiOffIcon extends StatefulWidget {
  @override
  State<_AnimatedWifiOffIcon> createState() => _AnimatedWifiOffIconState();
}

class _AnimatedWifiOffIconState extends State<_AnimatedWifiOffIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const double _baseSize = 120;
  static const Color _dangerRed = Color(0xFFE24C4C);
  static const Color _accentBlue = Color(0xFF3556E8);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRing(double t) {
    final double scale = 1.0 + (t * 0.55);
    final double opacity = (1 - t).clamp(0.0, 1.0) * .28;
    return Transform.scale(
      scale: scale,
      child: Container(
        height: _baseSize,
        width: _baseSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _accentBlue.withOpacity(opacity), width: 3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _baseSize + 60,
      width: _baseSize + 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  _buildRing(_controller.value),
                  _buildRing((_controller.value + 0.5) % 1.0),
                ],
              );
            },
          ),
          Container(
            height: _baseSize,
            width: _baseSize,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Container(
              height: _baseSize - 24,
              width: _baseSize - 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFEDEBF9), shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, size: 40, color: Color(0xFF565B75)),
            ),
          ),
          Positioned(
            top: 22,
            right: 22,
            child: Container(
              height: 26,
              width: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4E4),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.priority_high_rounded, size: 14, color: _dangerRed),
            ),
          ),
        ],
      ),
    );
  }
}