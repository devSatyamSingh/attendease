import 'package:flutter/material.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});


  static const _employeeName = "Rahul";
  static const _todayDateLabel = "Thursday, Oct 24, 2024";
  static const _avatarUrl = "https://i.pravatar.cc/150?img=12"; // placeholder

  static const _status = "WORKING"; // WORKING / CHECKED_OUT / NOT_CHECKED_IN
  static const _checkInTime = "10:08";
  static const _checkInMeridiem = "AM";
  static const _shiftLabel = "Standard Shift (09:00 AM – 06:00 PM)";
  static const _workedSoFar = "3h 42m";
  static const _dailyGoalPercent = 0.46;
  static const _dailyGoalTarget = "8h target";

  static final List<_ActivityItem> _recentActivity = [
    const _ActivityItem(
      dateLabel: "Yesterday, Oct 23",
      timeRange: "09:02 AM → 06:14 PM",
      workedLabel: "8h 42m",
      status: _ActivityStatus.completed,
    ),
    const _ActivityItem(
      dateLabel: "Tuesday, Oct 22",
      timeRange: "08:55 AM → 05:58 PM",
      workedLabel: "8h 03m",
      status: _ActivityStatus.completed,
    ),
    const _ActivityItem(
      dateLabel: "Monday, Oct 21",
      timeRange: "09:42 AM → 06:45 PM",
      workedLabel: "8h 03m",
      status: _ActivityStatus.late,
      lateMinutes: 12,
    ),
    const _ActivityItem(
      dateLabel: "Friday, Oct 18",
      timeRange: "09:05 AM → 06:10 PM",
      workedLabel: "8h 05m",
      status: _ActivityStatus.completed,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 18),
                  _buildGreetingRow(context),
                  const SizedBox(height: 18),
                  _buildStatusCard(context),
                  const SizedBox(height: 16),
                  _buildCheckOutButton(context),
                  const SizedBox(height: 20),
                  _buildStatsRow(context),
                  const SizedBox(height: 24),
                  _buildRecentActivityHeader(context),
                  const SizedBox(height: 12),
                  ..._recentActivity.map(
                        (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildActivityCard(context, item),
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
              AppText("Dashboard", fontSize: 22, fontWeight: FontWeight.w700),
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
        Container(
          height: 38,
          width: 38,
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.whiteColor,
            size: 20,
          ),
        ),
      ],
    );
  }

  // ==================== GREETING ROW ====================
  Widget _buildGreetingRow(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.fieldFillColor,
          backgroundImage: NetworkImage(_avatarUrl),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                "Good Morning, $_employeeName",
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 2),
              const CaptionText(_todayDateLabel),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: const BoxDecoration(
                color: AppColors.fieldFillColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.headlineTextColor,
              ),
            ),
            Positioned(
              top: 0,
              right: 2,
              child: Container(
                height: 9,
                width: 9,
                decoration: BoxDecoration(
                  color: AppColors.errorColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.whiteColor, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== HERO STATUS CARD ====================
  Widget _buildStatusCard(BuildContext context) {
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
              _buildStatusPill(_status),
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
                        "Within office premises",
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
            "CHECKED IN AT",
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: AppColors.whiteColor.withOpacity(.7),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                _checkInTime,
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: AppColors.whiteColor,
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppText(
                  _checkInMeridiem,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteColor.withOpacity(.8),
                ),
              ),
            ],
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
                  _shiftLabel,
                  fontSize: 12,
                  color: AppColors.whiteColor.withOpacity(.75),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildWorkedSoFarCard(context),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
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
            decoration: const BoxDecoration(
              color: AppColors.workingColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          AppText(
            status,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
            color: AppColors.whiteColor,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkedSoFarCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
                    size: 16,
                    color: AppColors.secondaryColor,
                  ),
                  const SizedBox(width: 6),
                  AppText(
                    "Worked so far",
                    fontSize: 13,
                    color: AppColors.whiteColor.withOpacity(.9),
                  ),
                ],
              ),
              AppText(
                _workedSoFar,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.whiteColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _dailyGoalPercent,
              minHeight: 7,
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
                "${(_dailyGoalPercent * 100).round()}% of daily goal",
                fontSize: 11,
                color: AppColors.whiteColor.withOpacity(.7),
              ),
              AppText(
                _dailyGoalTarget,
                fontSize: 11,
                color: AppColors.whiteColor.withOpacity(.7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== CHECK-OUT BUTTON ====================
  Widget _buildCheckOutButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        // TODO: call AttendanceViewModel.checkOut(context) here —
        // wrap with AppLoader.show(context)/.hide(context).
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.errorColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.errorColor.withOpacity(.3),
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
              decoration: BoxDecoration(
                color: AppColors.whiteColor.withOpacity(.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.whiteColor,
                  ),
                  SizedBox(height: 2),
                  AppText(
                    "Location Verified • Tap to end shift",
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

  // ==================== STATS ROW ====================
  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.calendar_month_rounded,
            iconColor: AppColors.primaryColor,
            title: "This Month",
            value: "18",
            label: "Present Days",
            footer: "+2 vs last mo",
            footerColor: AppColors.successColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warningColor,
            title: "Late Days",
            value: "01",
            label: "Late Arrival",
            footer: "Under threshold",
            footerColor: AppColors.labelTextColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.access_time_filled_rounded,
            iconColor: AppColors.infoColor,
            title: "Avg. Hours",
            value: "8.4h",
            label: "Per Day",
            footer: "On target",
            footerColor: AppColors.infoColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String value,
        required String label,
        required String footer,
        required Color footerColor,
      }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: AppText(
                  title,
                  fontSize: 11,
                  color: AppColors.labelTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 6),
          AppText(value, fontSize: 22, fontWeight: FontWeight.w700),
          const SizedBox(height: 2),
          AppText(label, fontSize: 11, color: AppColors.labelTextColor),
          const SizedBox(height: 2),
          AppText(
            footer,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: footerColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

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
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            // TODO: Navigator.pushNamed(context, AppRoutes.history);
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

  Widget _buildActivityCard(BuildContext context, _ActivityItem item) {
    final bool isLate = item.status == _ActivityStatus.late;
    final Color badgeColor = isLate ? AppColors.lateColor : AppColors.successColor;
    final Color iconBgColor = isLate
        ? AppColors.lateColor.withOpacity(.12)
        : AppColors.primaryColor.withOpacity(.1);
    final IconData icon =
    isLate ? Icons.watch_later_rounded : Icons.check_circle_rounded;
    final Color iconColor = isLate ? AppColors.lateColor : AppColors.primaryColor;
    final workedParts = item.workedLabel.split(" ");

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
                  item.dateLabel,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildStatusChip(
                  isLate ? "Late (${item.lateMinutes}m)" : "Completed",
                  badgeColor,
                ),
                const SizedBox(height: 6),
                AppText(
                  item.timeRange,
                  fontSize: 12,
                  color: AppColors.labelTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final part in workedParts)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fieldFillColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppText(part, fontSize: 11, fontWeight: FontWeight.w600),
                ),
            ],
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
          AppText(label, fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ],
      ),
    );
  }

}

class _ActivityItem {
  final String dateLabel;
  final String timeRange;
  final String workedLabel;
  final _ActivityStatus status;
  final int lateMinutes;

  const _ActivityItem({
    required this.dateLabel,
    required this.timeRange,
    required this.workedLabel,
    required this.status,
    this.lateMinutes = 0,
  });
}

enum _ActivityStatus { completed, late }