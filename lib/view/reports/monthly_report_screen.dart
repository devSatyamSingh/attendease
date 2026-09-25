import 'package:flutter/material.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  // ---- Replace with real data / ViewModel ----
  static const _monthLabel = "September 2026";
  static const _statusLabel = "Finalized & Approved";
  static const _workingDays = "22 Work Days";

  static const _totalHours = "182";
  static const _totalMinutes = "45";
  static const _targetLabel = "Target: 200h 00m";
  static const _remainingLabel = "Remaining: 17h 15m (91.4%)";
  static const _vsAvgLabel = "+4.2h vs Aug avg";
  static const _progress = 0.914;

  final List<_StatCard> _stats = const [
    _StatCard(
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.successColor,
      tag: "91%",
      tagColor: AppColors.successColor,
      value: "20",
      valueSuffix: " / 22",
      label: "Present Days",
    ),
    _StatCard(
      icon: Icons.watch_later_outlined,
      iconColor: AppColors.primaryColor,
      tag: "Grace",
      tagColor: AppColors.primaryColor,
      value: "02",
      label: "Late Days (<15m)",
    ),
    _StatCard(
      icon: Icons.login_rounded,
      iconColor: AppColors.infoColor,
      tag: "Half-day",
      tagColor: AppColors.infoColor,
      value: "01",
      label: "Early Checkout",
    ),
    _StatCard(
      icon: Icons.verified_user_outlined,
      iconColor: AppColors.workingColor,
      tag: "100%",
      tagColor: AppColors.workingColor,
      value: "00",
      label: "Missing Punch",
    ),
  ];

  final List<_PunctualityRow> _punctuality = const [
    _PunctualityRow(
      icon: Icons.alarm_rounded,
      label: "Total Late Arrival",
      value: "24 mins",
      progress: 0.55,
      color: AppColors.primaryColor,
    ),
    _PunctualityRow(
      icon: Icons.logout_rounded,
      label: "Early Departure (Approved)",
      value: "15 mins",
      progress: 0.35,
      color: AppColors.infoColor,
    ),
  ];

  final List<_DailyRow> _dailyRows = const [
    _DailyRow(
      dayLabel: "Sep 30, Wed",
      inOut: "09:00 AM – 05:45 PM",
      status: "On-time",
      statusColor: AppColors.successColor,
      hours: "8h",
      minutes: "45m",
    ),
    _DailyRow(
      dayLabel: "Sep 29, Tue",
      inOut: "09:14 AM – 05:30 PM",
      status: "Late +14m",
      statusColor: AppColors.primaryColor,
      hours: "8h",
      minutes: "16m",
    ),
    _DailyRow(
      dayLabel: "Sep 28, Mon",
      inOut: "08:58 AM – 06:00 PM",
      status: "On-time",
      statusColor: AppColors.successColor,
      hours: "9h",
      minutes: "02m",
    ),
    _DailyRow(
      dayLabel: "Sep 25, Fri",
      inOut: "08:45 AM – 04:30 PM",
      status: "Early -15m",
      statusColor: AppColors.infoColor,
      hours: "7h",
      minutes: "45m",
    ),
    _DailyRow(
      dayLabel: "Sep 24, Thu",
      inOut: "09:00 AM – 05:30 PM",
      status: "On-time",
      statusColor: AppColors.successColor,
      hours: "8h",
      minutes: "30m",
    ),
    _DailyRow(
      dayLabel: "Sep 23, Wed",
      inOut: "08:55 AM – 05:45 PM",
      status: "On-time",
      statusColor: AppColors.successColor,
      hours: "8h",
      minutes: "50m",
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _buildWelcomeHeader(context),
                const SizedBox(height: 20),
                _buildTopBar(context),
                const SizedBox(height: 16),
                _buildMonthSelector(context),
                const SizedBox(height: 18),
                _buildTotalHoursHero(context),
                const SizedBox(height: 16),
                _buildStatsGrid(context),
                const SizedBox(height: 18),
                _buildPunctualityCard(context),
                const SizedBox(height: 22),
                _buildDailyHeader(context),
                const SizedBox(height: 12),
                ..._dailyRows.map(
                      (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildDailyRow(r),
                  ),
                ),
                const SizedBox(height: 14),
                _buildExportButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== WELCOME HEADER ====================
  Widget _buildWelcomeHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          "Monthly Report",
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        Row(
          children: [
            _buildCircleIconButton(
              icon: Icons.notifications_none_rounded,
              onTap: () {
                // TODO: Navigator.pushNamed(context, RouteNames.notifications);
              },
            ),
            const SizedBox(width: 10),
            _buildCircleIconButton(
              icon: Icons.settings_outlined,
              onTap: () {
                // TODO: Navigator.pushNamed(context, RouteNames.settings);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
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

  // ==================== TOP BAR ====================
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        _buildCircleIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  "Monthly Report",
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 2),
                CaptionText("Attendance & Work Hours Analytics"),
              ],
            ),
          ),
        ),
        _buildCircleIconButton(
          icon: Icons.download_rounded,
          onTap: () {
            // TODO: export PDF
          },
        ),
      ],
    );
  }

  // ==================== MONTH SELECTOR ====================
  Widget _buildMonthSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  // TODO: previous month
                },
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.headlineTextColor,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    AppText(
                      _monthLabel,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  // TODO: next month
                },
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.headlineTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoPill(
                icon: Icons.verified_rounded,
                label: _statusLabel,
                color: AppColors.successColor,
              ),
              const SizedBox(width: 8),
              _buildInfoPill(
                icon: null,
                label: _workingDays,
                color: AppColors.labelTextColor,
                bgColor: AppColors.fieldFillColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill({
    IconData? icon,
    required String label,
    required Color color,
    Color? bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor ?? color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          AppText(
            label,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ],
      ),
    );
  }

  // ==================== TOTAL HOURS HERO ====================
  Widget _buildTotalHoursHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: AppColors.whiteColor,
                  ),
                  const SizedBox(width: 6),
                  AppText(
                    "TOTAL WORKED HOURS",
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.whiteColor.withOpacity(.9),
                  ),
                ],
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.whiteColor.withOpacity(.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      size: 12,
                      color: AppColors.whiteColor,
                    ),
                    const SizedBox(width: 5),
                    AppText(
                      _vsAvgLabel,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.whiteColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AppText(
                _totalHours,
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: AppColors.whiteColor,
              ),
              const SizedBox(width: 4),
              AppText(
                "h",
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.whiteColor.withOpacity(.85),
              ),
              const SizedBox(width: 12),
              AppText(
                _totalMinutes,
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: AppColors.whiteColor,
              ),
              const SizedBox(width: 4),
              AppText(
                "m",
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.whiteColor.withOpacity(.85),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: AppColors.whiteColor.withOpacity(.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.workingColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                _targetLabel,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.whiteColor.withOpacity(.85),
              ),
              AppText(
                _remainingLabel,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.whiteColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== STATS GRID ====================
  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: _stats.map(_buildStatCard).toList(),
    );
  }

  Widget _buildStatCard(_StatCard stat) {
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
              Container(
                height: 32,
                width: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: stat.iconColor.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(stat.icon, size: 16, color: stat.iconColor),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stat.tagColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppText(
                  stat.tag,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: stat.tagColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: stat.value,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.headlineTextColor,
                  ),
                ),
                if (stat.valueSuffix != null)
                  TextSpan(
                    text: stat.valueSuffix,
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.labelTextColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          CaptionText(stat.label),
        ],
      ),
    );
  }

  // ==================== PUNCTUALITY CARD ====================
  Widget _buildPunctualityCard(BuildContext context) {
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
              Row(
                children: [
                  const Icon(
                    Icons.timelapse_rounded,
                    size: 18,
                    color: AppColors.headlineTextColor,
                  ),
                  const SizedBox(width: 8),
                  AppText(
                    "Punctuality & Variance",
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
              CaptionText("Accumulated"),
            ],
          ),
          const SizedBox(height: 16),
          ..._punctuality.map((p) => _buildPunctualityRow(p)),
        ],
      ),
    );
  }

  Widget _buildPunctualityRow(_PunctualityRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(row.icon, size: 16, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: AppText(
                  row.label,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.bodyTextColor,
                ),
              ),
              AppText(
                row.value,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: row.color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: row.progress,
              minHeight: 6,
              backgroundColor: AppColors.fieldFillColor,
              valueColor: AlwaysStoppedAnimation<Color>(row.color),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DAILY BREAKDOWN ====================
  Widget _buildDailyHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            AppText(
              "Daily Breakdown",
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(width: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.fieldFillColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppText(
                "${_dailyRows.length} days",
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.labelTextColor,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () {
            // TODO: filter sheet
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.filter_list_rounded,
                size: 15,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 4),
              AppText(
                "Filter",
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyRow(_DailyRow row) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              color: row.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  row.dayLabel,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 3),
                CaptionText(row.inOut),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: row.statusColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: AppText(
              row.status,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: row.statusColor,
            ),
          ),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: row.hours,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.headlineTextColor,
                  ),
                ),
                TextSpan(
                  text: " ${row.minutes}",
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.labelTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EXPORT BUTTON ====================
  Widget _buildExportButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // TODO: export PDF / Excel
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.download_rounded,
              size: 20,
              color: AppColors.whiteColor,
            ),
            const SizedBox(width: 10),
            AppText(
              "Export Report (PDF / Excel)",
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.whiteColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DATA MODELS ====================
class _StatCard {
  final IconData icon;
  final Color iconColor;
  final String tag;
  final Color tagColor;
  final String value;
  final String? valueSuffix;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.tag,
    required this.tagColor,
    required this.value,
    this.valueSuffix,
    required this.label,
  });
}

class _PunctualityRow {
  final IconData icon;
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _PunctualityRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });
}

class _DailyRow {
  final String dayLabel;
  final String inOut;
  final String status;
  final Color statusColor;
  final String hours;
  final String minutes;

  const _DailyRow({
    required this.dayLabel,
    required this.inOut,
    required this.status,
    required this.statusColor,
    required this.hours,
    required this.minutes,
  });
}