import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/errors/failure.dart';
import '../../core/routes/route_name.dart';
import '../../model/holiday_model.dart';
import '../../model/leave_model.dart';
import '../../viewmodel/holiday_viewmodel.dart';
import '../../viewmodel/leave_viewmodel.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_loader.dart';
import '../../widget/app_text.dart';
import 'leave_ui_helper.dart';

class LeavesScreen extends ConsumerStatefulWidget {
  const LeavesScreen({super.key});

  @override
  ConsumerState<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends ConsumerState<LeavesScreen> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(leaveTypesProvider);
    final balanceAsync = ref.watch(leaveBalanceViewModelProvider);
    final recentAsync = ref.watch(recentLeaveRequestsProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive horizontal padding: smaller on small phones, capped on tablets/web.
    final hPad = (screenWidth * 0.045).clamp(12.0, 24.0);
    // Responsive max content width so it stays usable on tablets/web too.
    final maxContentWidth = screenWidth > 700 ? 520.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () => Future.wait([
                ref.read(leaveBalanceViewModelProvider.notifier).refresh(),
                ref.refresh(leaveTypesProvider.future),
                ref.refresh(recentLeaveRequestsProvider.future),
              ]),
              child: ListView(
                padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 16),
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 14),
                  _buildSectionHeader(
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Leave Balances",
                    trailing: _buildFyChip(ref),
                  ),
                  const SizedBox(height: 10),
                  _buildBalanceSection(typesAsync, balanceAsync, screenWidth),
                  const SizedBox(height: 20),
                  _buildQuickApplyHeader(context),
                  const SizedBox(height: 10),
                  _buildApplyButton(context),
                  const SizedBox(height: 12),
                  _buildPoolStatsRow(balanceAsync),
                  const SizedBox(height: 20),
                  _buildRecentRequestsHeader(context, recentAsync),
                  const SizedBox(height: 10),
                  _buildRecentSection(typesAsync, recentAsync),
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
      children: [
        InkWell(
          onTap: () => Navigator.maybePop(context),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.headlineTextColor),
          ),
        ),
        const Expanded(
          child: AppText("My Leaves", fontSize: 14, fontWeight: FontWeight.w600, textAlign: TextAlign.center),
        ),
        const SizedBox(width: 28), // balances the back icon so title stays centered
      ],
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: AppColors.headlineTextColor),
            const SizedBox(width: 6),
            AppText(title, fontSize: 13, fontWeight: FontWeight.w600),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildFyChip(WidgetRef ref) {
    final year = ref.read(leaveBalanceViewModelProvider.notifier).year;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.fieldFillColor, borderRadius: BorderRadius.circular(20)),
      child: AppText("FY $year", fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.labelTextColor),
    );
  }

  // ==================== BALANCE SECTION ====================
  Widget _buildBalanceSection(AsyncValue<List<LeaveTypeModel>> typesAsync,
      AsyncValue<List<LeaveBalanceModel>> balanceAsync, double screenWidth) {
    if (typesAsync.isLoading || balanceAsync.isLoading) {
      return const _BalanceCarouselSkeleton();
    }
    if (typesAsync.hasError) {
      return _buildInlineError(typesAsync.error!, () => ref.refresh(leaveTypesProvider));
    }
    if (balanceAsync.hasError) {
      return _buildInlineError(
          balanceAsync.error!, () => ref.read(leaveBalanceViewModelProvider.notifier).refresh());
    }

    final types = typesAsync.value ?? [];
    final balances = balanceAsync.value ?? [];

    if (balances.isEmpty) return _buildEmptyBalance();

    return Column(
      children: [
        _buildBalanceCarousel(types, balances, screenWidth),
        const SizedBox(height: 8),
        _buildPageIndicator(balances.length),
      ],
    );
  }

  Widget _buildBalanceCarousel(
      List<LeaveTypeModel> types, List<LeaveBalanceModel> balances, double screenWidth) {
    final cardHeight = (screenWidth * 0.38).clamp(140.0, 170.0);
    return SizedBox(
      height: cardHeight,
      child: PageView.builder(
        controller: PageController(viewportFraction: .95),
        itemCount: balances.length,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (context, index) {
          final balance = balances[index];
          final type = types.where((t) => t.leaveTypeId == balance.leaveTypeId).toList();
          final typeName = type.isNotEmpty ? type.first.name : "Leave";
          final code = type.isNotEmpty ? type.first.code : "";
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _buildBalanceCard(balance, typeName, code),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(LeaveBalanceModel balance, String typeName, String code) {
    final color = LeaveUiHelper.colorForCode(code);
    final icon = LeaveUiHelper.iconForCode(code);
    final progress = balance.allocatedDays == 0 ? 0.0 : balance.usedDays / balance.allocatedDays;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
                child: AppText(typeName, fontSize: 10, fontWeight: FontWeight.w600, color: color),
              ),
              Container(
                height: 24,
                width: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.whiteColor, borderRadius: BorderRadius.circular(7)),
                child: Icon(icon, size: 13, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Center(
              // AspectRatio forces a perfect 1:1 box regardless of the parent's
              // constraints, so the ring is always a true circle, never an oval.
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(value: 1, strokeWidth: 7, color: color.withOpacity(.15)),
                    ),
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress.clamp(0, 1),
                        strokeWidth: 7,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
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
                                text: balance.usedDays.toStringAsFixed(balance.usedDays % 1 == 0 ? 0 : 1),
                                style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.headlineTextColor,
                                    fontFamily: "Poppins"),
                              ),
                              TextSpan(
                                text:
                                "/${balance.allocatedDays.toStringAsFixed(balance.allocatedDays % 1 == 0 ? 0 : 1)}",
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.labelTextColor,
                                    fontFamily: "Poppins"),
                              ),
                            ],
                          ),
                        ),
                        const CaptionText("USED"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_bottom_rounded, size: 12, color: color),
                const SizedBox(width: 5),
                AppText(
                  "${balance.remainingDays.toStringAsFixed(balance.remainingDays % 1 == 0 ? 0 : 1)} Days Left",
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 16 : 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primaryColor : AppColors.borderColor,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyBalance() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: const Center(
        child: AppText("No leave balance found for this year", fontSize: 12, color: AppColors.labelTextColor),
      ),
    );
  }

  // ==================== QUICK APPLY ====================
  Widget _buildQuickApplyHeader(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText("Quick Apply", fontSize: 14, fontWeight: FontWeight.w600),
        CaptionText("Fast-track leave in 1 tap"),
      ],
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.pushNamed(context, RouteNames.applyLeave),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: AppColors.primaryColor.withOpacity(.3), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.event_note_rounded, color: AppColors.whiteColor, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: AppText("Apply for Leave", fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.whiteColor),
            ),
            Container(
              height: 26,
              width: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.whiteColor.withOpacity(.2), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: AppColors.whiteColor, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolStatsRow(AsyncValue<List<LeaveBalanceModel>> balanceAsync) {
    final totalPool = (balanceAsync.value ?? []).fold<double>(0, (sum, b) => sum + b.allocatedDays);
    final holidayAsync = ref.watch(holidayViewModelProvider);

    HolidayModel? nextHoliday;
    if (holidayAsync.hasValue) {
      final upcoming = [...holidayAsync.value!].where((h) => !h.isPast).toList()
        ..sort((a, b) => a.holidayDate.compareTo(b.holidayDate));
      if (upcoming.isNotEmpty) nextHoliday = upcoming.first;
    }

    return Row(
      children: [
        Expanded(
          child: _buildPoolStatCard(
            icon: Icons.donut_large_rounded,
            iconColor: AppColors.primaryColor,
            title: "TOTAL POOL",
            value: balanceAsync.isLoading ? "…" : "${totalPool.toStringAsFixed(totalPool % 1 == 0 ? 0 : 1)} Days",
            label: "Annual allowance total",
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPoolStatCard(
            icon: Icons.celebration_outlined,
            iconColor: AppColors.successColor,
            title: "NEXT HOLIDAY",
            value: nextHoliday != null ? DateFormat("dd MMM").format(nextHoliday.holidayDate) : "—",
            label: nextHoliday?.name ?? "No upcoming holiday",
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
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 5),
              Flexible(
                child: AppText(title,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.labelTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AppText(value, fontSize: 16, fontWeight: FontWeight.w600),
          const SizedBox(height: 2),
          CaptionText(label, textAlign: TextAlign.start),
        ],
      ),
    );
  }

  // ==================== RECENT REQUESTS ====================
  Widget _buildRecentRequestsHeader(BuildContext context, AsyncValue<List<LeaveRequestModel>> recentAsync) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const AppText("Recent Requests", fontSize: 14, fontWeight: FontWeight.w600),
        InkWell(
          onTap: () => Navigator.pushNamed(context, RouteNames.leaveHistory),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText("View All", fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryColor),
              Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primaryColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSection(
      AsyncValue<List<LeaveTypeModel>> typesAsync, AsyncValue<List<LeaveRequestModel>> recentAsync) {
    if (recentAsync.isLoading) return const _RecentListSkeleton();
    if (recentAsync.hasError) {
      return _buildInlineError(recentAsync.error!, () => ref.refresh(recentLeaveRequestsProvider));
    }

    final items = recentAsync.value ?? [];
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: const Center(
          child: AppText("No leave requests yet", fontSize: 12, color: AppColors.labelTextColor),
        ),
      );
    }

    final types = typesAsync.value ?? [];

    return Column(
      children: items
          .map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildRequestCard(r, types),
      ))
          .toList(),
    );
  }

  Widget _buildRequestCard(LeaveRequestModel request, List<LeaveTypeModel> types) {
    final type = types.where((t) => t.leaveTypeId == request.leaveTypeId).toList();
    final typeName = type.isNotEmpty ? type.first.name : "Leave";
    final code = type.isNotEmpty ? type.first.code : "";
    final icon = LeaveUiHelper.iconForCode(code);
    final statusColor = AppColors.requestStatusColor(request.status);

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
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primaryColor, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(typeName,
                          fontSize: 13, fontWeight: FontWeight.w600, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    _buildStatusChip(request.status, statusColor),
                  ],
                ),
                const SizedBox(height: 3),
                CaptionText(_dateRangeLabel(request)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _buildTagChip("${request.totalDays.toStringAsFixed(request.totalDays % 1 == 0 ? 0 : 1)} Day"),
                    _buildTagChip(LeaveUiHelper.durationLabel(request.leaveDurationType)),
                  ],
                ),
                if (request.reason != null && request.reason!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  AppText('"${request.reason}"',
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.labelTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateRangeLabel(LeaveRequestModel r) {
    final fmt = DateFormat("dd MMM yyyy");
    if (r.isSingleDay) return fmt.format(r.startDate);
    return "${DateFormat("dd MMM").format(r.startDate)} – ${fmt.format(r.endDate)}";
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.fieldFillColor, borderRadius: BorderRadius.circular(20)),
      child: AppText(label, fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.labelTextColor),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: status.toUpperCase() == 'PENDING' ? 6 : 10, color: color),
          const SizedBox(width: 3),
          AppText(status, fontSize: 9, fontWeight: FontWeight.w600, color: color),
        ],
      ),
    );
  }

  // ==================== SHARED ERROR ====================
  Widget _buildInlineError(Object error, VoidCallback onRetry) {
    final message = error is Failure ? error.message : "Something went wrong.";
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
          const Icon(Icons.wifi_off_rounded, color: AppColors.errorColor, size: 18),
          const SizedBox(width: 8),
          Expanded(child: AppText(message, fontSize: 12, color: AppColors.labelTextColor)),
          TextButton(
            onPressed: onRetry,
            child: const AppText("Retry", fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryColor),
          ),
        ],
      ),
    );
  }
}

// ==================== SKELETONS ====================
class _BalanceCarouselSkeleton extends StatelessWidget {
  const _BalanceCarouselSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: SizedBox(
            width: 210,
            child: AppSkeletonBox(height: 160, borderRadius: 16),
          ),
        ),
      ),
    );
  }
}

class _RecentListSkeleton extends StatelessWidget {
  const _RecentListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppSkeletonBox(height: 108, borderRadius: 16),
        );
      }),
    );
  }
}