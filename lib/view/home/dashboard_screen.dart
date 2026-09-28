import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failure.dart';
import '../../core/routes/route_name.dart';
import '../../model/attendance_model.dart';
import '../../services/permission_service.dart';
import '../../utils/app_utils.dart';
import '../../viewmodel/attendance_viewmodel.dart';
import '../../viewmodel/profile_viewmodel.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_loader.dart';
import '../../widget/app_text.dart';
import '../attendance/attendance_status.dart';
import '../attendance/check_in_out_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _ensureLocationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensureLocationPermission();
    }
  }

  Future<void> _ensureLocationPermission() async {
    try {
      await PermissionService().ensureLocationPermission();
    } on Failure catch (f) {
      if (!mounted) return;
      _showLocationPermissionDialog(f);
    } catch (_) {}
  }

  void _showLocationPermissionDialog(Failure failure) {
    final bool permanentlyDenied = failure.message.toLowerCase().contains(
      "permanently",
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AppText(
          "Location needed",
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        content: AppText(
          failure.message,
          fontSize: 12,
          color: AppColors.labelTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const AppText(
              "Not now",
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (permanentlyDenied) {
                await PermissionService().openAppSettings();
              } else {
                await _ensureLocationPermission();
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

  Future<void> _openCheckIn(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CheckInScreen()));
    if (!mounted) return;
    ref.read(attendanceViewModelProvider.notifier).refresh();
  }

  Future<void> _handleCheckOut(BuildContext context) async {
    final success = await ref
        .read(attendanceViewModelProvider.notifier)
        .checkOut();
    if (!mounted) return;

    if (success) {
      AppUtils.showSnackbar(context, "Checked out — see you tomorrow!");
      ref.invalidate(recentAttendanceProvider);
    } else {
      final error = ref.read(attendanceViewModelProvider).error;
      AppUtils.showErrorSnackbar(
        context,
        error is Failure
            ? error.message
            : "Couldn't check out. Please try again.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceViewModelProvider);
    final recentActivityAsync = ref.watch(recentAttendanceProvider);
    final profileAsync = ref.watch(profileViewModelProvider);
    final firstName = profileAsync.value?.name.split(" ").first;

    final screenWidth = MediaQuery.of(context).size.width;
    // LeavesScreen jaisa hi responsive padding + max width
    final hPad = (screenWidth * 0.045).clamp(12.0, 24.0);
    final maxContentWidth = screenWidth > 700 ? 520.0 : double.infinity;
    // Hero ring screen ke hisaab se scale hoga (64 – 78)
    final ringSize = (screenWidth * 0.2).clamp(64.0, 78.0);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () async {
                await _ensureLocationPermission();
                await Future.wait([
                  ref.read(attendanceViewModelProvider.notifier).refresh(),
                  ref.refresh(recentAttendanceProvider.future),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 16),
                children: [
                  _buildHeader(context, firstName),
                  const SizedBox(height: 14),
                  attendanceState.when(
                    loading: () => const _StatusCardSkeleton(),
                    error: (error, _) => _buildStatusErrorCard(context, error),
                    data: (today) => Column(
                      children: [
                        _buildHeroCard(context, today, ringSize),
                        const SizedBox(height: 12),
                        _buildActionArea(
                          context,
                          today,
                          attendanceState.isLoading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRecentActivityHeader(context),
                  const SizedBox(height: 10),
                  recentActivityAsync.when(
                    loading: () => const _ActivityListSkeleton(),
                    error: (error, _) =>
                        _buildActivityErrorCard(context, error),
                    data: (items) => items.isEmpty
                        ? _buildEmptyActivityCard()
                        : Column(
                      children: items
                          .map(
                            (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildActivityCard(context, item),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== HEADER (avatar + greeting + bell) ====================
  Widget _buildHeader(BuildContext context, String? firstName) {
    final hasName = firstName?.isNotEmpty ?? false;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primaryLight,
          child: AppText(
            hasName ? firstName![0].toUpperCase() : "?",
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CaptionText("${AppUtils.getGreeting()},"),
              const SizedBox(height: 1),
              AppText(
                hasName ? firstName! : "Welcome back",
                fontSize: 15,
                fontWeight: FontWeight.w600,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            // TODO: Navigator.pushNamed(context, AppRoutes.notifications);
          },
          customBorder: const CircleBorder(),
          child: Container(
            height: 38,
            width: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cardBgColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderColor),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: AppColors.headlineTextColor,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== HERO STATUS CARD ====================
  Widget _buildHeroCard(
      BuildContext context,
      AttendanceModel? today,
      double ringSize,
      ) {
    final bool checkedIn = today?.actualCheckIn != null;
    final bool checkedOut = today?.actualCheckOut != null;
    final ds = today?.displayStatus;
    final bool blocked =
        ds == AttendanceDisplayStatus.onLeave ||
            ds == AttendanceDisplayStatus.holiday;

    final String statusLabel = blocked
        ? today!.statusLabel.toUpperCase()
        : (checkedOut
        ? "CHECKED OUT"
        : (checkedIn ? "WORKING" : "NOT CHECKED IN"));
    final Color pillDotColor = blocked
        ? AppColors.secondaryColor
        : (checkedOut
        ? AppColors.checkedOutColor
        : (checkedIn
        ? AppColors.workingColor
        : AppColors.notCheckedInColor));

    final int? worked = _workedMinutes(today);
    final int goalMinutes = AppConstants.defaultDailyGoalHours * 60;
    final double percent = worked == null
        ? 0.0
        : (worked / goalMinutes).clamp(0.0, 1.0);

    final String captionLabel = checkedOut
        ? "CHECKED OUT AT"
        : (checkedIn
        ? "CHECKED IN AT"
        : (blocked ? "TODAY" : "READY WHEN YOU ARE"));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // ---- decorative circles (modern glass feel) ----
            Positioned(
              top: -34,
              right: -24,
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.whiteColor.withOpacity(.08),
                ),
              ),
            ),
            Positioned(
              bottom: -46,
              left: -30,
              child: Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.whiteColor.withOpacity(.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- row 1: status pill + verified ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusPill(statusLabel, pillDotColor),
                      if (today?.deviceId != null)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 13,
                                color: AppColors.whiteColor,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: AppText(
                                  "Verified device",
                                  fontSize: 11,
                                  color: AppColors.whiteColor.withOpacity(.85),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ---- row 2: time block + progress ring ----
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              captionLabel,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: AppColors.whiteColor.withOpacity(.7),
                            ),
                            const SizedBox(height: 4),
                            if (checkedIn || checkedOut)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  AppText(
                                    _timeOnly(
                                      checkedOut
                                          ? today!.actualCheckOut!
                                          : today!.actualCheckIn!,
                                    ),
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.whiteColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: AppText(
                                      _meridiem(
                                        checkedOut
                                            ? today.actualCheckOut!
                                            : today.actualCheckIn!,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.whiteColor.withOpacity(
                                        .8,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              AppText(
                                blocked
                                    ? today!.statusSubtitle
                                    : "Start your day",
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.whiteColor,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: AppColors.whiteColor.withOpacity(.75),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: AppText(
                                    "${_formatExpected(today?.expectedLoginTime)} – ${_formatExpected(today?.expectedLogoutTime)}",
                                    fontSize: 11,
                                    color: AppColors.whiteColor.withOpacity(
                                      .75,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildProgressRing(
                        size: ringSize,
                        percent: percent,
                        showPercent: checkedIn || checkedOut,
                        fallbackIcon: blocked
                            ? today!.statusIcon
                            : Icons.fingerprint_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ---- row 3: 3 glass stat tiles ----
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroTile(
                          icon: Icons.login_rounded,
                          label: "CHECK IN",
                          value: checkedIn
                              ? _fullTime(today!.actualCheckIn!)
                              : "--:--",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHeroTile(
                          icon: Icons.logout_rounded,
                          label: "CHECK OUT",
                          value: checkedOut
                              ? _fullTime(today!.actualCheckOut!)
                              : (checkedIn ? "Working" : "--:--"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHeroTile(
                          icon: Icons.timelapse_rounded,
                          label: "WORKED",
                          value: worked != null ? _durationLabel(worked) : "--",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.whiteColor.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          AppText(
            status,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: .5,
            color: AppColors.whiteColor,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing({
    required double size,
    required double percent,
    required bool showPercent,
    required IconData fallbackIcon,
  }) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 6,
              color: AppColors.whiteColor.withOpacity(.18),
            ),
          ),
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 6,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondaryColor,
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          if (showPercent)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  "${(percent * 100).round()}%",
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteColor,
                ),
                AppText(
                  "of goal",
                  fontSize: 9,
                  color: AppColors.whiteColor.withOpacity(.75),
                ),
              ],
            )
          else
            Icon(fallbackIcon, size: 26, color: AppColors.whiteColor),
        ],
      ),
    );
  }

  Widget _buildHeroTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.whiteColor.withOpacity(.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.whiteColor.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: AppColors.whiteColor.withOpacity(.75)),
              const SizedBox(width: 4),
              Flexible(
                child: AppText(
                  label,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .5,
                  color: AppColors.whiteColor.withOpacity(.75),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          AppText(
            value,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.whiteColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== ACTION AREA (Check In / Check Out / Done) ====================
  Widget _buildActionArea(
      BuildContext context,
      AttendanceModel? today,
      bool isBusy,
      ) {
    final bool checkedIn = today?.actualCheckIn != null;
    final bool checkedOut = today?.actualCheckOut != null;
    final ds = today?.displayStatus;

    // Leave / Holiday: check-in allowed nahi.
    if (ds == AttendanceDisplayStatus.onLeave ||
        ds == AttendanceDisplayStatus.holiday) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(today!.statusIcon, size: 18, color: AppColors.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: AppText(
                "${today.statusSubtitle} — no check-in needed today",
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    if (checkedOut) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.successColor.withOpacity(.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.successColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.whiteColor,
                size: 17,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    "Done for today",
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.successColor,
                  ),
                  SizedBox(height: 2),
                  CaptionText("See you tomorrow!"),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (checkedIn) {
      return _buildActionButton(
        onTap: isBusy ? null : () => _handleCheckOut(context),
        color: AppColors.errorColor,
        title: "CHECK OUT",
        subtitle: "Tap to end shift",
        leading: isBusy
            ? const SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.whiteColor,
          ),
        )
            : const Icon(
          Icons.logout_rounded,
          color: AppColors.whiteColor,
          size: 18,
        ),
      );
    }

    // Not checked in yet.
    return _buildActionButton(
      onTap: isBusy ? null : () => _openCheckIn(context),
      gradient: AppColors.primaryGradient,
      shadowColor: AppColors.primaryColor,
      title: "CHECK IN",
      subtitle: "Tap to verify location & mark attendance",
      leading: const Icon(
        Icons.fingerprint_rounded,
        color: AppColors.whiteColor,
        size: 20,
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onTap,
    required String title,
    required String subtitle,
    required Widget leading,
    Color? color,
    Gradient? gradient,
    Color? shadowColor,
  }) {
    final Color shadow = shadowColor ?? color ?? AppColors.primaryColor;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadow.withOpacity(.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.whiteColor.withOpacity(.15),
                shape: BoxShape.circle,
              ),
              child: leading,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.whiteColor,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    subtitle,
                    fontSize: 11,
                    color: AppColors.whiteColor.withOpacity(.9),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppColors.whiteColor,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ERROR CARDS ====================
  Widget _buildStatusErrorCard(BuildContext context, Object error) {
    final message = error is Failure
        ? error.message
        : "Couldn't load today's status.";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 18,
            color: AppColors.errorColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppText(
              message,
              fontSize: 12,
              color: AppColors.labelTextColor,
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(attendanceViewModelProvider.notifier).refresh(),
            child: const AppText(
              "Retry",
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityErrorCard(BuildContext context, Object error) {
    final message = error is Failure
        ? error.message
        : "Couldn't load recent activity.";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.errorColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppText(
              message,
              fontSize: 12,
              color: AppColors.labelTextColor,
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(recentAttendanceProvider),
            child: const AppText(
              "Retry",
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== RECENT ACTIVITY ====================
  Widget _buildRecentActivityHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 17,
              color: AppColors.headlineTextColor,
            ),
            SizedBox(width: 6),
            AppText("Recent Activity", fontSize: 13, fontWeight: FontWeight.w600),
          ],
        ),
        InkWell(
          onTap: () => Navigator.pushNamed(context, RouteNames.history),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                "View All",
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Container(
            height: 46,
            width: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          const AppText(
            "No activity yet",
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 3),
          const AppText(
            "Your check-ins will show up here once you get started.",
            fontSize: 11,
            color: AppColors.labelTextColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, AttendanceModel item) {
    final bool inProgress =
        item.displayStatus == AttendanceDisplayStatus.working;

    final Color color = item.statusColor;
    final IconData icon = item.statusIcon;

    final dateLabel = item.attendanceDate != null
        ? DateFormat("EEEE, MMM d").format(item.attendanceDate!.toLocal())
        : "—";

    final String timeRange = item.actualCheckIn == null
        ? item.statusSubtitle
        : "${_fullTime(item.actualCheckIn!)} → "
        "${item.actualCheckOut != null ? _fullTime(item.actualCheckOut!) : (inProgress ? 'Working' : '--:--')}";

    final workedLabel = item.workedMinutes != null
        ? _durationLabel(item.workedMinutes!)
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  dateLabel,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildStatusChip(item.statusLabel, color),
                const SizedBox(height: 6),
                AppText(
                  timeRange,
                  fontSize: 11,
                  color: AppColors.labelTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (workedLabel != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.fieldFillColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppText(
                workedLabel,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.labelTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          AppText(
            label,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================
  /// Worked minutes: checkout ho gaya to server value / diff, warna live elapsed.
  int? _workedMinutes(AttendanceModel? today) {
    if (today == null || today.actualCheckIn == null) return null;
    if (today.workedMinutes != null) return today.workedMinutes;
    final end = today.actualCheckOut?.toLocal() ?? DateTime.now();
    final diff = end.difference(today.actualCheckIn!.toLocal()).inMinutes;
    return diff < 0 ? 0 : diff;
  }

  String _durationLabel(int minutes) =>
      "${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m";

  String _fullTime(DateTime dt) => "${_timeOnly(dt)} ${_meridiem(dt)}";

  String _timeOnly(DateTime dt) {
    final local = dt.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return "$hour12:${local.minute.toString().padLeft(2, '0')}";
  }

  String _meridiem(DateTime dt) => dt.toLocal().hour >= 12 ? "PM" : "AM";

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
}

// ==================== SKELETONS ====================
class _StatusCardSkeleton extends StatelessWidget {
  const _StatusCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeletonBox(height: 22, width: 100, borderRadius: 20),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonBox(height: 10, width: 90, borderRadius: 6),
                    const SizedBox(height: 8),
                    AppSkeletonBox(height: 30, width: 130, borderRadius: 8),
                    const SizedBox(height: 8),
                    AppSkeletonBox(height: 10, width: 110, borderRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppSkeletonBox(height: 70, width: 70, borderRadius: 35),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: AppSkeletonBox(height: 46, borderRadius: 14)),
              const SizedBox(width: 8),
              Expanded(child: AppSkeletonBox(height: 46, borderRadius: 14)),
              const SizedBox(width: 8),
              Expanded(child: AppSkeletonBox(height: 46, borderRadius: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityListSkeleton extends StatelessWidget {
  const _ActivityListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
            (i) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            children: [
              AppSkeletonBox(height: 38, width: 38, borderRadius: 12),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonBox(height: 12, width: 120, borderRadius: 6),
                    const SizedBox(height: 8),
                    AppSkeletonBox(height: 10, width: 90, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}