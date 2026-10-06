import 'dart:async';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/constants/app_constants.dart';
import '../../core/errors/failure.dart';
import '../../model/attendance_model.dart';
import '../../services/device_security_service.dart';
import '../../services/location_service.dart';
import '../../services/permission_service.dart';
import '../../utils/app_utils.dart';
import '../../viewmodel/attendance_viewmodel.dart';
import '../../viewmodel/device_security_viewmodel.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';

/// Time / number ka order Urdu me ulta na ho.
String _ltrIso(String s) => '\u2066$s\u2069';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  Position? _position;
  bool _locatingPreview = true;
  bool _mockDetected = false;
  String? _blockMessage;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
    _primeLocation();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  // ==================== LOCATION + SECURITY CHECK ====================
  Future<void> _primeLocation() async {
    try {
      // App-wide banner ko bhi fresh state do
      await ref.read(deviceSecurityProvider.notifier).recheck();
      final security = await DeviceSecurityService().check();
      final position = await LocationService().getCurrentLocation();
      if (!mounted) return;

      final mocked = security.isMockLocation || position.isMocked;
      setState(() {
        _position = position;
        _locatingPreview = false;
        _mockDetected = mocked || !security.isSafe;
        _blockMessage = mocked
            ? 'check_in.mock_detected'.tr()
            : (security.isSafe ? null : security.message);
      });

      if (_mockDetected) _showSecurityDialog(_blockMessage!);
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _locatingPreview = false);
      _showLocationBlockedDialog(f);
    } catch (e) {
      if (!mounted) return;
      setState(() => _locatingPreview = false);
      AppUtils.showErrorSnackbar(
        context,
        'check_in.loc_error'.tr(),
      );
    }
  }

  void _showSecurityDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: AppText('check_in.action_blocked'.tr(), fontSize: 16, fontWeight: FontWeight.w500),
        content: AppText(message, fontSize: 13, color: AppColors.labelTextColor),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: AppText('check_in.close'.tr(), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _primeLocation(); // dobara check
            },
            child: AppText(
              'check_in.check_again'.tr(),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationBlockedDialog(Failure failure) {
    final bool permanentlyDenied =
    failure.message.toLowerCase().contains("permanently");
    final bool gpsUnavailable = failure.code == "GPS_UNAVAILABLE";

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: AppText(
          gpsUnavailable
              ? 'check_in.gps_not_responding'.tr()
              : 'dashboard.location_needed'.tr(),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        content: AppText(failure.message, fontSize: 13, color: AppColors.labelTextColor),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: AppText('dashboard.not_now'.tr(), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (gpsUnavailable)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await PermissionService().openLocationSettings();
              },
              child: AppText(
                'check_in.location_settings'.tr(),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (permanentlyDenied) {
                await PermissionService().openAppSettings();
              } else {
                await _primeLocation();
              }
            },
            child: AppText(
              permanentlyDenied
                  ? 'dashboard.open_settings'.tr()
                  : (gpsUnavailable ? 'check_in.try_again'.tr() : 'dashboard.allow'.tr()),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAP HANDLER ====================
  Future<void> _handleTap(AttendanceModel? today) async {
    final notifier = ref.read(attendanceViewModelProvider.notifier);
    final bool success = (today == null || !_isCheckedIn(today))
        ? await notifier.checkIn()
        : await notifier.checkOut();

    if (!mounted) return;

    if (success) {
      final justCheckedIn = today == null || !_isCheckedIn(today);
      AppUtils.showSnackbar(
        context,
        justCheckedIn
            ? 'check_in.checked_in_success'.tr()
            : 'dashboard.checkout_success'.tr(),
      );
      _primeLocation();
    } else {
      final error = ref.read(attendanceViewModelProvider).error;
      if (error is Failure) {
        const securityCodes = {
          "MOCK_LOCATION_DETECTED",
          "DEVICE_ROOTED",
          "EMULATOR_DETECTED",
        };
        if (error.code == "GPS_PERMISSION_REQUIRED") {
          _showLocationBlockedDialog(error);
        } else if (securityCodes.contains(error.code)) {
          setState(() {
            _mockDetected = true;
            _blockMessage = error.message;
          });
          ref.read(deviceSecurityProvider.notifier).recheck();
          _showSecurityDialog(error.message);
        } else {
          AppUtils.showErrorSnackbar(context, error.message);
        }
      } else {
        AppUtils.showErrorSnackbar(context, 'errors.generic'.tr());
      }
    }
  }

  bool _isCheckedIn(AttendanceModel a) => a.actualCheckIn != null && a.actualCheckOut == null;
  bool _isCheckedOut(AttendanceModel a) => a.actualCheckOut != null;

  String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  String _formatAmPm(DateTime dt) => dt.hour >= 12 ? "PM" : "AM";

  // Hardcoded weekday/month lists hata di: ab selected language me aayega
  String _formatDate(DateTime dt) =>
      DateFormat("EEE, MMM d", context.locale.toString()).format(dt);

  String _formatTimeOfDay(DateTime dt) {
    final local = dt.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    return _ltrIso("$hour12:$m ${local.hour >= 12 ? 'PM' : 'AM'}");
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final attendanceState = ref.watch(attendanceViewModelProvider);
    final today = attendanceState.value;
    final bool isBusy = attendanceState.isLoading;

    // App-wide security state (banner se sync rehne ke liye)
    final globalSecurity = ref.watch(deviceSecurityProvider).value;
    final bool globalBlocked = globalSecurity != null && !globalSecurity.isSafe;
    final bool blocked = _mockDetected || globalBlocked;
    final String? blockText = _blockMessage ?? (globalBlocked ? globalSecurity.message : null);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _buildTopBar(context),
                const SizedBox(height: 20),
                _buildLocationCard(context),
                if (blocked && blockText != null) ...[
                  const SizedBox(height: 12),
                  _buildWarningCard(blockText),
                ],
                const SizedBox(height: 18),
                _buildStatusCard(context),
                const SizedBox(height: 26),
                _buildActionButton(context, size, today, isBusy, blocked),
                const SizedBox(height: 14),
                _buildHelperText(today),
                const SizedBox(height: 22),
                _buildTodayTimeline(context, today),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== WARNING CARD ====================
  Widget _buildWarningCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.errorColor.withOpacity(.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.errorColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: AppText(message, fontSize: 12, color: AppColors.errorColor),
          ),
        ],
      ),
    );
  }

  // ==================== TOP BAR ====================
  Widget _buildTopBar(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCircleIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Column(
            children: [
              AppText('check_in.title'.tr(), fontSize: 16, fontWeight: FontWeight.w600),
              const SizedBox(height: 2),
              CaptionText('check_in.subtitle'.tr(), textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildCircleIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        height: 40,
        width: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Icon(icon, color: AppColors.headlineTextColor, size: 20),
      ),
    );
  }

  // ==================== LOCATION CARD (real GPS reading) ====================
  Widget _buildLocationCard(BuildContext context) {
    final bool ready = _position != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ready ? AppColors.successColor.withOpacity(.08) : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 39,
            width: 39,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ready ? AppColors.successColor : AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ready ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
              color: AppColors.whiteColor,
              size: 17,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  _locatingPreview
                      ? 'check_in.detecting'.tr()
                      : (ready ? 'check_in.location_ready'.tr() : 'check_in.location_unavailable'.tr()),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(height: 2),
                CaptionText(
                  ready
                      ? 'check_in.accuracy'.tr(
                    args: [_ltrIso("±${_position!.accuracy.round()}m")],
                  )
                      : 'check_in.tap_to_allow'.tr(),
                ),
              ],
            ),
          ),
          if (!_locatingPreview)
            TextButton(
              onPressed: _primeLocation,
              child: AppText(
                'check_in.refresh'.tr(),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  // ==================== STATUS CARD (Clock) ====================
  Widget _buildStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: _buildStatusRow(
        icon: Icons.access_time_rounded,
        iconColor: AppColors.primaryColor,
        title: 'check_in.live_clock'.tr(),
        subtitle: _formatDate(_now),
        // Clock + AM/PM hamesha isi order me (Urdu me ulta nahi hoga)
        trailing: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AppText(_formatClock(_now), fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.primaryColor),
              const SizedBox(width: 4),
              AppText(_formatAmPm(_now), fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(title, fontSize: 13, fontWeight: FontWeight.w500),
              const SizedBox(height: 2),
              CaptionText(subtitle),
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  // ==================== ACTION BUTTON ====================
  Widget _buildActionButton(
      BuildContext context,
      Size size,
      AttendanceModel? today,
      bool isBusy,
      bool blocked,
      ) {
    final double buttonSize = size.width * 0.50 > 160 ? 160 : size.width * 0.50;

    final bool checkedOut = today != null && _isCheckedOut(today);
    final bool checkedIn = today != null && _isCheckedIn(today);
    final bool active = !checkedOut && !isBusy && !blocked;

    final String label = checkedOut
        ? 'check_in.btn_done'.tr()
        : (checkedIn ? 'dashboard.btn_check_out'.tr() : 'dashboard.btn_check_in'.tr());
    final IconData icon = checkedOut
        ? Icons.check_circle_rounded
        : (blocked
        ? Icons.block_rounded
        : (checkedIn ? Icons.logout_rounded : Icons.fingerprint_rounded));

    // Blocked ya done -> grey, warna gradient
    final bool greyed = checkedOut || blocked;
    final Gradient? gradient = greyed
        ? null
        : LinearGradient(
      colors: checkedIn
          ? [AppColors.errorColor, AppColors.rejectedColor]
          : [AppColors.primaryColor, AppColors.primaryDark],
    );

    final String subLabel = checkedOut
        ? 'check_in.for_today'.tr()
        : (blocked ? 'check_in.blocked'.tr() : 'check_in.tap_to_verify'.tr());

    return Center(
      child: SizedBox(
        height: buttonSize + 40,
        width: buttonSize + 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (active)
              _PulsingRing(
                size: buttonSize,
                color: checkedIn ? AppColors.errorColor : AppColors.primaryColor,
              ),
            GestureDetector(
              onTap: active ? () => _handleTap(today) : null,
              child: Container(
                height: buttonSize,
                width: buttonSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: greyed ? AppColors.disabledColor : null,
                  gradient: gradient,
                  boxShadow: greyed
                      ? []
                      : [
                    BoxShadow(
                      color: (checkedIn ? AppColors.errorColor : AppColors.primaryColor)
                          .withOpacity(.35),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: isBusy
                    ? const SizedBox(
                  height: 40,
                  width: 40,
                  child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.whiteColor),
                )
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor.withOpacity(.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppColors.whiteColor, size: 20),
                    ),
                    const SizedBox(height: 12),
                    AppText(
                      label,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.whiteColor,
                      letterSpacing: 1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      subLabel,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.whiteColor.withOpacity(.85),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelperText(AttendanceModel? today) {
    final bool checkedOut = today != null && _isCheckedOut(today);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 22,
          width: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
          child: Icon(
            checkedOut ? Icons.event_available_rounded : Icons.verified_user_outlined,
            size: 13,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppText(
            checkedOut
                ? 'check_in.helper_done'.tr()
                : 'check_in.helper_gps'.tr(),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.bodyTextColor,
          ),
        ),
      ],
    );
  }

  // ==================== TODAY'S TIMELINE ====================
  Widget _buildTodayTimeline(BuildContext context, AttendanceModel? today) {
    final checkInLabel = today?.actualCheckIn != null
        ? _formatTimeOfDay(today!.actualCheckIn!)
        : 'check_in.pending'.tr();
    final checkOutLabel = today?.actualCheckOut != null
        ? _formatTimeOfDay(today!.actualCheckOut!)
        : 'check_in.expected'.tr(
      args: [_ltrIso(_formatExpected(today?.expectedLogoutTime))],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText('check_in.timeline_title'.tr(), fontSize: 13, fontWeight: FontWeight.w600),
                    const SizedBox(height: 2),
                    CaptionText('check_in.timeline_sub'.tr()),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                child: AppText(
                  _ltrIso("${_formatExpected(today?.expectedLoginTime)} – ${_formatExpected(today?.expectedLogoutTime)}"),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildTimelineRow(
            icon: Icons.check_circle_rounded,
            iconColor: today?.actualCheckIn != null ? AppColors.workingColor : AppColors.labelTextColor,
            title: 'check_in.tl_check_in'.tr(),
            subtitle: today?.lateMinutes != null && today!.lateMinutes! > 0
                ? 'check_in.late_by'.tr(args: ['${today.lateMinutes}'])
                : 'check_in.on_schedule'.tr(),
            trailing: checkInLabel,
            trailingColor: today?.actualCheckIn != null ? AppColors.workingColor : AppColors.bodyTextColor,
            showConnector: true,
          ),
          const SizedBox(height: 6),
          _buildTimelineRow(
            icon: Icons.schedule_rounded,
            iconColor: today?.actualCheckOut != null ? AppColors.workingColor : AppColors.labelTextColor,
            title: 'check_in.tl_check_out'.tr(),
            subtitle: 'check_in.office_departure'.tr(),
            trailing: checkOutLabel,
            trailingColor: AppColors.bodyTextColor,
            showConnector: false,
          ),
        ],
      ),
    );
  }

  String _formatExpected(String? hms) {
    if (hms == null) return "--:--";
    try {
      final parts = hms.split(":");
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      return "$hour12:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}";
    } catch (_) {
      return hms;
    }
  }

  Widget _buildTimelineRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String trailing,
    required Color trailingColor,
    required bool showConnector,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                height: 22,
                width: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: iconColor.withOpacity(.15), shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              if (showConnector) Expanded(child: Container(width: 2, color: AppColors.borderColor)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(title, fontSize: 12, fontWeight: FontWeight.w600),
                  const SizedBox(height: 2),
                  CaptionText(subtitle),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          AppText(trailing, fontSize: 11, fontWeight: FontWeight.w500, color: trailingColor),
        ],
      ),
    );
  }
}

class _PulsingRing extends StatefulWidget {
  final double size;
  final Color color;
  const _PulsingRing({required this.size, required this.color});

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
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
    );
  }

  Widget _buildRing(double t) {
    final double scale = 1.0 + (t * 0.35);
    final double opacity = (1 - t).clamp(0.0, 1.0) * 0.35;
    return Transform.scale(
      scale: scale,
      child: Container(
        height: widget.size,
        width: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: widget.color.withOpacity(opacity), width: 3),
        ),
      ),
    );
  }
}