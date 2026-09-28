import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/errors/failure.dart';
import '../../core/routes/route_name.dart';
import '../../model/leave_model.dart';
import '../../utils/app_topbar.dart';
import '../../viewmodel/leave_viewmodel.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';
import 'leave_ui_helper.dart';

class LeaveHistoryScreen extends ConsumerStatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  ConsumerState<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends ConsumerState<LeaveHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(leaveHistoryViewModelProvider.notifier).loadMore();
      }
    });

    Future.microtask(
          () => ref.read(leaveHistoryViewModelProvider.notifier).loadFirstPage(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(leaveHistoryViewModelProvider);
    final typesAsync = ref.watch(leaveTypesProvider);
    final countsAsync = ref.watch(leaveStatusCountsProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    // LeavesScreen jaisa hi responsive padding + max width
    final hPad = (screenWidth * 0.045).clamp(12.0, 24.0);
    final maxContentWidth = screenWidth > 700 ? 520.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 0),
                  child: Column(
                    children: [
                      const AppTopBar(title: "Leave History"),
                      const SizedBox(height: 10),
                      _buildFilterRow(historyState, countsAsync),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryColor,
                    onRefresh: () => Future.wait([
                      ref.read(leaveHistoryViewModelProvider.notifier).refresh(),
                      ref.refresh(leaveStatusCountsProvider.future),
                    ]),
                    child: _buildList(historyState, typesAsync, hPad),
                  ),
                ),
                _buildBottomBar(context, hPad),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== FILTERS ====================
  Widget _buildFilterRow(historyState, AsyncValue<Map<String, int>> countsAsync) {
    final counts = countsAsync.value;
    return Row(
      children: [
        Expanded(
          child: _buildFilterChip(
            label: "All",
            status: null,
            count: counts?["ALL"],
            currentFilter: historyState.statusFilter,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterChip(
            label: "Pending",
            status: "PENDING",
            count: counts?["PENDING"],
            currentFilter: historyState.statusFilter,
            color: AppColors.pendingColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterChip(
            label: "Approved",
            status: "APPROVED",
            count: counts?["APPROVED"],
            currentFilter: historyState.statusFilter,
            color: AppColors.approvedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? status,
    required int? count,
    required String? currentFilter,
    required Color color,
  }) {
    final bool selected = currentFilter == status;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => ref.read(leaveHistoryViewModelProvider.notifier).setStatusFilter(status),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.borderColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!selected)
              Container(
                height: 6,
                width: 6,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            AppText(
              label,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.whiteColor : AppColors.bodyTextColor,
            ),
            const SizedBox(width: 4),
            AppText(
              count != null ? "$count" : "…",
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.whiteColor : AppColors.labelTextColor,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== LIST ====================
  Widget _buildList(
      historyState,
      AsyncValue<List<LeaveTypeModel>> typesAsync,
      double hPad,
      ) {
    if (historyState.isLoading) return _HistorySkeleton(hPad: hPad);

    if (historyState.isEmpty && historyState.failure != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 12),
        children: [_buildErrorState(historyState.failure!)],
      );
    }

    if (historyState.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
        children: [_buildEmptyState()],
      );
    }

    final types = typesAsync.value ?? [];

    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
      children: [
        ...historyState.items.map<Widget>(
              (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildHistoryCard(item, types),
          ),
        ),
        if (historyState.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.2)),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 32, color: AppColors.placeholderColor),
          SizedBox(height: 8),
          AppText("No leave requests found", fontSize: 12, color: AppColors.labelTextColor),
        ],
      ),
    );
  }

  Widget _buildErrorState(Failure failure) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 28, color: AppColors.errorColor),
          const SizedBox(height: 8),
          AppText(
            failure.message,
            fontSize: 12,
            color: AppColors.labelTextColor,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => ref.read(leaveHistoryViewModelProvider.notifier).refresh(),
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

  // ==================== HISTORY CARD ====================
  Widget _buildHistoryCard(LeaveRequestModel item, List<LeaveTypeModel> types) {
    final type = types.where((t) => t.leaveTypeId == item.leaveTypeId).toList();
    final typeName = type.isNotEmpty ? type.first.name : "Leave";
    final code = type.isNotEmpty ? type.first.code : "";
    final icon = LeaveUiHelper.iconForCode(code);
    final accent = AppColors.requestStatusColor(item.status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.cardBgColor,
                borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 38,
                        width: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 18, color: AppColors.primaryColor),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: AppText(
                          typeName,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusChip(item.status, accent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppColors.labelTextColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: CaptionText(_dateRangeLabel(item))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      _buildTagChip(
                        "${item.totalDays.toStringAsFixed(item.totalDays % 1 == 0 ? 0 : 1)} Day",
                      ),
                      _buildTagChip(LeaveUiHelper.durationLabel(item.leaveDurationType)),
                    ],
                  ),
                  if (item.reason != null && item.reason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    AppText(
                      '"${item.reason}"',
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.labelTextColor,
                    ),
                  ],
                  if (item.appliedAt != null) ...[
                    const SizedBox(height: 6),
                    CaptionText(
                      "Applied on ${DateFormat("dd MMM • hh:mm a").format(item.appliedAt!.toLocal())}",
                    ),
                  ],
                  if (item.isRejected &&
                      item.rejectionReason != null &&
                      item.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor.withOpacity(.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: AppColors.errorColor,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: AppText(
                              "Admin Note: ${item.rejectionReason}",
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
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
      decoration: BoxDecoration(
        color: AppColors.fieldFillColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppText(
        label,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.labelTextColor,
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          AppText(status, fontSize: 9, fontWeight: FontWeight.w600, color: color),
        ],
      ),
    );
  }

  // ==================== BOTTOM BAR ====================
  Widget _buildBottomBar(BuildContext context, double hPad) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 12),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBgColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, RouteNames.applyLeave),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.whiteColor),
              SizedBox(width: 8),
              AppText(
                "Request Time Off",
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.whiteColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  final double hPad;
  const _HistorySkeleton({required this.hPad});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
      children: List.generate(4, (i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
          ),
        );
      }),
    );
  }
}