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
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        content: AppText(
          failure.message,
          fontSize: 13,
          color: AppColors.labelTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const AppText(
              "Not now",
              fontSize: 13,
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
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

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 18),
                  _buildGreetingRow(context, firstName),
                  const SizedBox(height: 18),
                  attendanceState.when(
                    loading: () => const _StatusCardSkeleton(),
                    error: (error, _) => _buildStatusErrorCard(context, error),
                    data: (today) => Column(
                      children: [
                        _buildStatusCard(context, today),
                        const SizedBox(height: 16),
                        _buildActionArea(
                          context,
                          today,
                          attendanceState.isLoading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRecentActivityHeader(context),
                  const SizedBox(height: 12),
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
                                    padding: const EdgeInsets.only(bottom: 12),
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

  // ==================== TOP BAR ====================
  Widget _buildTopBar(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CaptionText("Welcome back,"),
              AppText("Dashboard", fontSize: 17, fontWeight: FontWeight.w600),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: Navigator.pushNamed(context, AppRoutes.notifications);
          },
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.headlineTextColor,
          ),
        ),
      ],
    );
  }

  // ==================== GREETING ROW ====================
  Widget _buildGreetingRow(BuildContext context, String? firstName) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primaryLight,
          child: AppText(
            (firstName?.isNotEmpty ?? false)
                ? firstName![0].toUpperCase()
                : "?",
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                "${AppUtils.getGreeting()}, ${firstName ?? ''}".trim(),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CaptionText(
                DateFormat("EEEE, MMM d, yyyy").format(DateTime.now()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== HERO STATUS CARD ====================
  Widget _buildStatusCard(BuildContext context, AttendanceModel? today) {
    final bool checkedIn = today?.actualCheckIn != null;
    final bool checkedOut = today?.actualCheckOut != null;
    final String statusLabel = checkedOut
        ? "CHECKED OUT"
        : (checkedIn ? "WORKING" : "NOT CHECKED IN");
    final Color pillDotColor = checkedOut
        ? AppColors.checkedOutColor
        : (checkedIn ? AppColors.workingColor : AppColors.notCheckedInColor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
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
                        size: 14,
                        color: AppColors.whiteColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: AppText(
                          "Verified device",
                          fontSize: 12,
                          color: AppColors.whiteColor.withOpacity(.85),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          AppText(
            checkedOut
                ? "CHECKED OUT AT"
                : (checkedIn ? "CHECKED IN AT" : "READY WHEN YOU ARE"),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: AppColors.whiteColor.withOpacity(.7),
          ),
          const SizedBox(height: 6),
          if (checkedIn || checkedOut)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppText(
                  _timeOnly(
                    checkedOut ? today!.actualCheckOut! : today!.actualCheckIn!,
                  ),
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteColor,
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppText(
                    _meridiem(
                      checkedOut
                          ? today!.actualCheckOut!
                          : today!.actualCheckIn!,
                    ),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.whiteColor.withOpacity(.8),
                  ),
                ),
              ],
            )
          else
            AppText(
              "Tap Check In below to start your day",
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.whiteColor,
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppColors.whiteColor.withOpacity(.75),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: AppText(
                  "${_formatExpected(today?.expectedLoginTime)} – ${_formatExpected(today?.expectedLogoutTime)}",
                  fontSize: 12,
                  color: AppColors.whiteColor.withOpacity(.75),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (checkedIn) ...[
            const SizedBox(height: 18),
            _buildWorkedSoFarCard(today!),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.whiteColor.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 7,
            width: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          AppText(
            status,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: .5,
            color: AppColors.whiteColor,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkedSoFarCard(AttendanceModel today) {
    final elapsedMinutes =
        today.workedMinutes ??
        DateTime.now().difference(today.actualCheckIn!.toLocal()).inMinutes;
    final goalMinutes = AppConstants.defaultDailyGoalHours * 60;
    final percent = (elapsedMinutes / goalMinutes).clamp(0.0, 1.0);
    final h = elapsedMinutes ~/ 60;
    final m = elapsedMinutes % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.whiteColor.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timelapse_rounded,
                    size: 14,
                    color: AppColors.secondaryColor,
                  ),
                  const SizedBox(width: 6),
                  AppText(
                    "Worked so far",
                    fontSize: 11,
                    color: AppColors.whiteColor.withOpacity(.9),
                  ),
                ],
              ),
              AppText(
                "${h}h ${m.toString().padLeft(2, '0')}m",
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.whiteColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 5,
              backgroundColor: AppColors.whiteColor.withOpacity(.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                "${(percent * 100).round()}% of daily goal",
                fontSize: 11,
                color: AppColors.whiteColor.withOpacity(.7),
              ),
              AppText(
                "${AppConstants.defaultDailyGoalHours}h target",
                fontSize: 11,
                color: AppColors.whiteColor.withOpacity(.7),
              ),
            ],
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

    if (checkedOut) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.successColor.withOpacity(.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.successColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.whiteColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    "Done for today",
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.successColor,
                  ),
                  const SizedBox(height: 2),
                  const AppText(
                    "See you tomorrow!",
                    fontSize: 12,
                    color: AppColors.bodyTextColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (checkedIn) {
      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isBusy ? null : () => _handleCheckOut(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.errorColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.errorColor.withOpacity(.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
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
                child: isBusy
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
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      "CHECK OUT",
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.whiteColor,
                    ),
                    SizedBox(height: 2),
                    AppText(
                      "Tap to end shift",
                      fontSize: 11,
                      color: AppColors.whiteColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Not checked in yet.
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isBusy ? null : () => _openCheckIn(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(.3),
              blurRadius: 14,
              offset: const Offset(0, 8),
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
              child: const Icon(
                Icons.fingerprint_rounded,
                color: AppColors.whiteColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    "CHECK IN",
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.whiteColor,
                  ),
                  SizedBox(height: 2),
                  AppText(
                    "Tap to verify location & mark attendance",
                    fontSize: 11,
                    color: AppColors.whiteColor,
                  ),
                ],
              ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.errorColor),
          const SizedBox(width: 10),
          Expanded(
            child: AppText(
              message,
              fontSize: 13,
              color: AppColors.labelTextColor,
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(attendanceViewModelProvider.notifier).refresh(),
            child: const AppText(
              "Retry",
              fontSize: 12,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
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
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
              size: 18,
              color: AppColors.headlineTextColor,
            ),
            SizedBox(width: 6),
            AppText(
              "Recent Activity",
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, RouteNames.history);
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                "View All",
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
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
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 24,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 14),
          const AppText(
            "No activity yet",
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 4),
          AppText(
            "Your check-ins will show up here once you get started.",
            fontSize: 12,
            color: AppColors.labelTextColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, AttendanceModel item) {
    final bool isLate = (item.lateMinutes ?? 0) > 0;
    final bool inProgress = item.actualCheckOut == null;
    final Color badgeColor = isLate
        ? AppColors.lateColor
        : AppColors.successColor;
    final Color iconBgColor = isLate
        ? AppColors.lateColor.withOpacity(.12)
        : AppColors.primaryColor.withOpacity(.1);
    final IconData icon = isLate
        ? Icons.watch_later_rounded
        : Icons.check_circle_rounded;
    final Color iconColor = isLate
        ? AppColors.lateColor
        : AppColors.primaryColor;

    final dateLabel = item.attendanceDate != null
        ? DateFormat("EEEE, MMM d").format(item.attendanceDate!.toLocal())
        : "—";
    final timeRange = item.actualCheckIn != null
        ? "${_timeOnly(item.actualCheckIn!)} ${_meridiem(item.actualCheckIn!)} → ${inProgress ? 'In Progress' : '${_timeOnly(item.actualCheckOut!)} ${_meridiem(item.actualCheckOut!)}'}"
        : "—";
    final workedLabel = item.workedMinutes != null
        ? "${item.workedMinutes! ~/ 60}h ${(item.workedMinutes! % 60).toString().padLeft(2, '0')}m"
        : "--";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  dateLabel,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildStatusChip(
                  inProgress
                      ? "In Progress"
                      : (isLate ? "Late (${item.lateMinutes}m)" : "Completed"),
                  inProgress ? AppColors.infoColor : badgeColor,
                ),
                const SizedBox(height: 6),
                AppText(
                  timeRange,
                  fontSize: 12,
                  color: AppColors.labelTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.fieldFillColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppText(
              workedLabel,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
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
          const SizedBox(width: 5),
          AppText(
            label,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }

  // ==================== FORMAT HELPERS ====================
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSkeletonBox(height: 22, width: 90, borderRadius: 20),
              AppSkeletonBox(height: 16, width: 70, borderRadius: 20),
            ],
          ),
          const SizedBox(height: 26),
          AppSkeletonBox(height: 42, width: 140, borderRadius: 10),
          const SizedBox(height: 20),
          AppSkeletonBox(height: 64, borderRadius: 16),
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
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            children: [
              AppSkeletonBox(height: 40, width: 40, borderRadius: 12),
              const SizedBox(width: 12),
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
