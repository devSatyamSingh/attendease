import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failure.dart';
import '../../model/attendance_model.dart';
import '../../services/location_service.dart';
import '../../services/permission_service.dart';
import '../../utils/app_utils.dart';
import '../../viewmodel/attendance_viewmodel.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';

/// AttendEase — Check In / Check Out screen.
///
/// Real flow:
/// - On screen open, location permission is primed once (`_primeLocation`)
///   so the OS permission dialog shows up immediately rather than only
///   when the button is tapped.
/// - The big circular button reads its label/action from today's real
///   attendance record (`attendanceViewModelProvider`):
///     no record yet          -> "CHECK IN"
///     checked in, no checkout -> "CHECK OUT"
///     checked out             -> disabled, "Done for today"
///   The backend enforces one check-in and one check-out per calendar
///   day anyway — this just mirrors that so the button never lets the
///   employee try an action that would fail.
/// - Every tap goes through [LocationService.getCurrentLocation], which
///   already asks for permission, checks GPS is on, and rejects a fix
///   that's too inaccurate — so a location/permission problem simply
///   surfaces as the normal error snackbar and the action never reaches
///   the server.
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

  /// Asks for location permission the moment this screen opens (not
  /// only when the button is tapped) and fetches one fix to show real
  /// GPS accuracy on the card. If permission is permanently denied, an
  /// explanatory dialog with a direct "Open Settings" action is shown —
  /// the employee can't be left guessing why check-in won't work.
  Future<void> _primeLocation() async {
    try {
      final position = await LocationService().getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _position = position;
        _locatingPreview = false;
      });
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _locatingPreview = false);
      _showLocationBlockedDialog(f);
    } catch (e) {
      if (!mounted) return;
      setState(() => _locatingPreview = false);
      // Ab silent fail nahi hoga — kam se kam ek snackbar dikhega taaki
      // user ko pata chale refresh ne kya try kiya aur kyun fail hua.
      AppUtils.showErrorSnackbar(
        context,
        "Couldn't get your location. Please check GPS/permission and try again.",
      );
    }
  }

  void _showLocationBlockedDialog(Failure failure) {
    final bool permanentlyDenied =
    failure.message.toLowerCase().contains("permanently");
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AppText("Location needed", fontSize: 16, fontWeight: FontWeight.w500),
        content: AppText(failure.message, fontSize: 13, color: AppColors.labelTextColor),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const AppText("Not now", fontSize: 13, fontWeight: FontWeight.w500),
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
              permanentlyDenied ? "Open Settings" : "Allow",
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

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
        justCheckedIn ? "Checked in successfully." : "Checked out — see you tomorrow!",
      );
      // Refresh the on-card GPS accuracy reading for the next glance.
      _primeLocation();
    } else {
      final error = ref.read(attendanceViewModelProvider).error;
      if (error is Failure) {
        if (error.code == "GPS_PERMISSION_REQUIRED") {
          _showLocationBlockedDialog(error);
        } else {
          AppUtils.showErrorSnackbar(context, error.message);
        }
      } else {
        AppUtils.showErrorSnackbar(context, "Something went wrong. Please try again.");
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

  String _formatDate(DateTime dt) {
    const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}";
  }

  String _formatTimeOfDay(DateTime dt) {
    final local = dt.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    return "$hour12:$m ${local.hour >= 12 ? 'PM' : 'AM'}";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final attendanceState = ref.watch(attendanceViewModelProvider);
    final today = attendanceState.value;
    final bool isBusy = attendanceState.isLoading;

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
                const SizedBox(height: 18),
                _buildStatusCard(context),
                const SizedBox(height: 26),
                _buildActionButton(context, size, today, isBusy),
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
              AppText("Check In", fontSize: 16, fontWeight: FontWeight.w600),
              const SizedBox(height: 2),
              CaptionText("Location & Attendance Verification"),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ready ? AppColors.successColor.withOpacity(.08) : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ready ? AppColors.successColor : AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ready ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
              color: AppColors.whiteColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  _locatingPreview
                      ? "Detecting location..."
                      : (ready ? "Location ready" : "Location unavailable"),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(height: 2),
                CaptionText(
                  ready
                      ? "±${_position!.accuracy.round()}m accuracy"
                      : "Tap to allow location and try again",
                ),
              ],
            ),
          ),
          if (!_locatingPreview)
            TextButton(
              onPressed: _primeLocation,
              child: const AppText(
                "Refresh",
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  // ==================== STATUS CARD (Clock + GPS accuracy) ====================
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
        title: "Live System Clock",
        subtitle: _formatDate(_now),
        trailing: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AppText(_formatClock(_now), fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            AppText(_formatAmPm(_now), fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primaryColor),
          ],
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
          height: 42,
          width: 42,
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
  Widget _buildActionButton(BuildContext context, Size size, AttendanceModel? today, bool isBusy) {
    final double buttonSize = size.width * 0.62 > 240 ? 240 : size.width * 0.62;

    final bool checkedOut = today != null && _isCheckedOut(today);
    final bool checkedIn = today != null && _isCheckedIn(today);
    final bool active = !checkedOut && !isBusy;

    final String label = checkedOut ? "DONE" : (checkedIn ? "CHECK OUT" : "CHECK IN");
    final IconData icon = checkedOut
        ? Icons.check_circle_rounded
        : (checkedIn ? Icons.logout_rounded : Icons.fingerprint_rounded);
    final Gradient? gradient = checkedOut
        ? null
        : LinearGradient(
      colors: checkedIn
          ? [AppColors.errorColor, AppColors.rejectedColor]
          : [AppColors.primaryColor, AppColors.primaryDark],
    );

    return Center(
      child: SizedBox(
        height: buttonSize + 40,
        width: buttonSize + 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (active) _PulsingRing(size: buttonSize, color: checkedIn ? AppColors.errorColor : AppColors.primaryColor),
            GestureDetector(
              onTap: active ? () => _handleTap(today) : null,
              child: Container(
                height: buttonSize,
                width: buttonSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: checkedOut ? AppColors.disabledColor : null,
                  gradient: gradient,
                  boxShadow: checkedOut
                      ? []
                      : [
                    BoxShadow(
                      color: (checkedIn ? AppColors.errorColor : AppColors.primaryColor).withOpacity(.35),
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
                      height: 48,
                      width: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor.withOpacity(.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppColors.whiteColor, size: 26),
                    ),
                    const SizedBox(height: 12),
                    AppText(
                      label,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.whiteColor,
                      letterSpacing: 1,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      checkedOut ? "for today" : "Tap to verify",
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.whiteColor.withOpacity(.85),
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
                ? "You're done for today. This resets automatically tomorrow."
                : "Make sure location is on before tapping — the check-in needs a live GPS fix.",
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
    final checkInLabel = today?.actualCheckIn != null ? _formatTimeOfDay(today!.actualCheckIn!) : "Pending";
    final checkOutLabel = today?.actualCheckOut != null
        ? _formatTimeOfDay(today!.actualCheckOut!)
        : "Expected ${_formatExpected(today?.expectedLogoutTime)}";

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText("Today's Timeline", fontSize: 13, fontWeight: FontWeight.w600),
                  const SizedBox(height: 2),
                  CaptionText("Scheduled Work Session"),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                child: AppText(
                  "${_formatExpected(today?.expectedLoginTime)} – ${_formatExpected(today?.expectedLogoutTime)}",
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildTimelineRow(
            icon: Icons.check_circle_rounded,
            iconColor: today?.actualCheckIn != null ? AppColors.workingColor : AppColors.labelTextColor,
            title: "Check-in",
            subtitle: today?.lateMinutes != null && today!.lateMinutes! > 0
                ? "Late by ${today.lateMinutes}m"
                : "On schedule",
            trailing: checkInLabel,
            trailingColor: today?.actualCheckIn != null ? AppColors.workingColor : AppColors.bodyTextColor,
            showConnector: true,
          ),
          const SizedBox(height: 6),
          _buildTimelineRow(
            icon: Icons.schedule_rounded,
            iconColor: today?.actualCheckOut != null ? AppColors.workingColor : AppColors.labelTextColor,
            title: "Check-out",
            subtitle: "Office boundary departure",
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
          AppText(trailing, fontSize: 12, fontWeight: FontWeight.w600, color: trailingColor),
        ],
      ),
    );
  }
}

/// Radar-style pulsing ring drawn behind the check-in/check-out button
/// while it's actionable — two rings offset in phase, each expanding
/// outward and fading as it grows, looping continuously.
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