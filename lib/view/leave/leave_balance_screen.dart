import 'package:flutter/material.dart';
import '../../core/routes/route_name.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';

/// AttendEase — "My Leaves" landing screen.
/// Shows leave balances (swipeable), a quick-apply CTA, pool/holiday
/// stats, and the most recent leave requests.
class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  static const _fyLabel = "FY 2026";
  static const _totalPoolDays = "23 Days";
  static const _nextHolidayDate = "02 Oct";
  static const _nextHolidayName = "Gandhi Jayanti";

  static final List<_LeaveBalance> _balances = [
    const _LeaveBalance(
      type: "Casual Leave",
      icon: Icons.wb_sunny_outlined,
      used: 3,
      total: 12,
      daysLeft: 9,
      color: AppColors.primaryColor,
    ),
    const _LeaveBalance(
      type: "Sick Leave",
      icon: Icons.local_hospital_outlined,
      used: 1,
      total: 8,
      daysLeft: 7,
      color: AppColors.errorColor,
    ),
    const _LeaveBalance(
      type: "Earned Leave",
      icon: Icons.flight_takeoff_rounded,
      used: 5,
      total: 15,
      daysLeft: 10,
      color: AppColors.successColor,
    ),
    const _LeaveBalance(
      type: "Comp-Off",
      icon: Icons.change_circle_outlined,
      used: 0,
      total: 3,
      daysLeft: 3,
      color: AppColors.secondaryColor,
    ),
  ];

  static final List<_LeaveRequest> _recentRequests = [
    const _LeaveRequest(
      title: "Sick Leave",
      icon: Icons.medical_services_outlined,
      iconBg: AppColors.primaryLight,
      dateLabel: "28 Sep – 29 Sep 2026",
      tags: ["2 Days", "Full Day"],
      reason: "Doctor appointment & recovery",
      status: "PENDING",
    ),
    const _LeaveRequest(
      title: "Casual Leave",
      icon: Icons.wb_sunny_outlined,
      iconBg: AppColors.primaryLight,
      dateLabel: "15 Sep 2026",
      tags: ["0.5 Day", "Second Half"],
      reason: "Personal errand",
      status: "APPROVED",
    ),
    const _LeaveRequest(
      title: "Earned Leave",
      icon: Icons.flight_takeoff_rounded,
      iconBg: AppColors.secondaryLight,
      dateLabel: "22 Aug – 25 Aug 2026",
      tags: ["4 Days", "Full Day"],
      reason: "Family trip",
      status: "APPROVED",
    ),
    const _LeaveRequest(
      title: "Casual Leave",
      icon: Icons.event_busy_rounded,
      iconBg: Color(0xFFFDE8E8),
      dateLabel: "10 Aug 2026",
      tags: ["1 Day", "Full Day"],
      reason: "Short notice request",
      status: "REJECTED",
    ),
  ];

  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _buildTopBar(context),
                const SizedBox(height: 20),
                _buildSectionHeader(
                  icon: Icons.account_balance_wallet_outlined,
                  title: "Leave Balances",
                  trailing: _buildFyChip(),
                ),
                const SizedBox(height: 14),
                _buildBalanceCarousel(context),
                const SizedBox(height: 12),
                _buildPageIndicator(),
                const SizedBox(height: 28),
                _buildQuickApplyHeader(context),
                const SizedBox(height: 14),
                _buildApplyButton(context),
                const SizedBox(height: 16),
                _buildPoolStatsRow(context),
                const SizedBox(height: 28),
                _buildRecentRequestsHeader(context),
                const SizedBox(height: 14),
                ..._recentRequests.map(
                      (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRequestCard(context, r),
                  ),
                ),
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
      children: [
        InkWell(
          onTap: () => Navigator.maybePop(context),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.arrow_back_rounded, color: AppColors.headlineTextColor),
          ),
        ),
        Expanded(
          child: AppText(
            "My Leaves",
            fontSize: 18,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
        ),
        InkWell(
          onTap: () => Navigator.pushNamed(context, RouteNames.applyLeave),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.add_rounded, color: AppColors.primaryColor, size: 26),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.headlineTextColor),
            const SizedBox(width: 8),
            AppText(title, fontSize: 17, fontWeight: FontWeight.w700),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildFyChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.fieldFillColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppText(
        _fyLabel,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.labelTextColor,
      ),
    );
  }

  // ==================== BALANCE CAROUSEL ====================
  Widget _buildBalanceCarousel(BuildContext context) {
    return SizedBox(
      height: 210,
      child: PageView.builder(
        controller: PageController(viewportFraction: .88),
        itemCount: _balances.length,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildBalanceCard(_balances[index]),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(_LeaveBalance balance) {
    final double progress = balance.total == 0 ? 0 : balance.used / balance.total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: balance.color.withOpacity(.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: balance.color.withOpacity(.18)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: balance.color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppText(
                  balance.type,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: balance.color,
                ),
              ),
              Container(
                height: 30,
                width: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.event_available_rounded, size: 16, color: balance.color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: SizedBox(
                height: 118,
                width: 118,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 9,
                        color: balance.color.withOpacity(.15),
                      ),
                    ),
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress.clamp(0, 1),
                        strokeWidth: 9,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(balance.color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "${balance.used}",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.headlineTextColor,
                                  fontFamily: "Poppins",
                                ),
                              ),
                              TextSpan(
                                text: "/${balance.total}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.labelTextColor,
                                  fontFamily: "Poppins",
                                ),
                              ),
                            ],
                          ),
                        ),
                        CaptionText("USED"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10,),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: balance.color.withOpacity(.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_bottom_rounded, size: 14, color: balance.color),
                const SizedBox(width: 6),
                AppText(
                  "${balance.daysLeft} Days Left",
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: balance.color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_balances.length, (i) {
        final bool active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 7,
          width: active ? 20 : 7,
          decoration: BoxDecoration(
            color: active ? AppColors.primaryColor : AppColors.borderColor,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  // ==================== QUICK APPLY ====================
  Widget _buildQuickApplyHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText("Quick Apply", fontSize: 17, fontWeight: FontWeight.w700),
        CaptionText("Fast-track leave in 1 tap"),
      ],
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pushNamed(context, RouteNames.applyLeave),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.event_note_rounded, color: AppColors.whiteColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
                "Apply for Leave",
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.whiteColor,
              ),
            ),
            Container(
              height: 32,
              width: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.whiteColor.withOpacity(.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: AppColors.whiteColor, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildPoolStatCard(
            icon: Icons.donut_large_rounded,
            iconColor: AppColors.primaryColor,
            title: "TOTAL POOL",
            value: _totalPoolDays,
            label: "Annual allowance total",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPoolStatCard(
            icon: Icons.celebration_outlined,
            iconColor: AppColors.successColor,
            title: "NEXT HOLIDAY",
            value: _nextHolidayDate,
            label: _nextHolidayName,
          ),
        ),
      ],
    );
  }

  Widget _buildPoolStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String label,
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
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: AppText(
                  title,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.labelTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppText(value, fontSize: 20, fontWeight: FontWeight.w700),
          const SizedBox(height: 2),
          CaptionText(label, textAlign: TextAlign.start),
        ],
      ),
    );
  }

  // ==================== RECENT REQUESTS ====================
  Widget _buildRecentRequestsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText("Recent Requests", fontSize: 17, fontWeight: FontWeight.w700),
        InkWell(
          onTap: () => Navigator.pushNamed(context, RouteNames.leaveHistory),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                "View All (${_recentRequests.length + 4})",
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primaryColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(BuildContext context, _LeaveRequest request) {
    final Color statusColor = AppColors.requestStatusColor(request.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: request.iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(request.icon, color: AppColors.primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        request.title,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusChip(request.status, statusColor),
                  ],
                ),
                const SizedBox(height: 4),
                CaptionText(request.dateLabel),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: request.tags.map((t) => _buildTagChip(t)).toList(),
                ),
                const SizedBox(height: 8),
                AppText(
                  '"${request.reason}"',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.labelTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.fieldFillColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppText(
        label,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.labelTextColor,
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    IconData icon;
    switch (status.toUpperCase()) {
      case 'APPROVED':
        icon = Icons.check_rounded;
        break;
      case 'REJECTED':
        icon = Icons.close_rounded;
        break;
      default:
        icon = Icons.circle;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: status == 'PENDING' ? 7 : 12, color: color),
          const SizedBox(width: 4),
          AppText(status, fontSize: 10, fontWeight: FontWeight.w700, color: color),
        ],
      ),
    );
  }
}

class _LeaveBalance {
  final String type;
  final IconData icon;
  final int used;
  final int total;
  final int daysLeft;
  final Color color;

  const _LeaveBalance({
    required this.type,
    required this.icon,
    required this.used,
    required this.total,
    required this.daysLeft,
    required this.color,
  });
}

class _LeaveRequest {
  final String title;
  final IconData icon;
  final Color iconBg;
  final String dateLabel;
  final List<String> tags;
  final String reason;
  final String status;

  const _LeaveRequest({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.dateLabel,
    required this.tags,
    required this.reason,
    required this.status,
  });
}