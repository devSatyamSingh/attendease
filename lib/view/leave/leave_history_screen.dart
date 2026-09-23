import 'package:flutter/material.dart';
import '../../core/routes/route_name.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';

/// AttendEase — "Leave History" screen.
/// Status-filterable list of every leave application with cancel /
/// admin-note affordances, plus a bottom shortcut back into the
/// apply-leave flow.
class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

enum _StatusFilter { all, pending, approved }

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  static const _fyLabel = "FY 2026–2027";

  static final List<_HistoryItem> _items = [
    const _HistoryItem(
      title: "Sick Leave (SL)",
      icon: Icons.medical_services_outlined,
      iconBg: Color(0xFFFDEBD3),
      status: "PENDING",
      accentColor: AppColors.pendingColor,
      dateLabel: "28 Sep – 29 Sep 2026",
      tags: ["2 Days", "Full Day"],
      reason: "Severe seasonal flu and doctor consultation scheduled.",
      appliedLabel: "Applied on 24 Sep • 09:30 AM",
      cancellable: true,
    ),
    const _HistoryItem(
      title: "Casual Leave (CL)",
      icon: Icons.wb_sunny_outlined,
      iconBg: Color(0xFFDCF5E8),
      status: "APPROVED",
      accentColor: AppColors.approvedColor,
      dateLabel: "15 Sep 2026",
      tags: ["0.5 Day", "Second Half (13:30 - 18:00)"],
      reason: "Attending bank appointment and personal errand.",
      appliedLabel: "Applied on 12 Sep",
      approvedByLabel: "Approved by Devon Vance (Lead)",
    ),
    const _HistoryItem(
      title: "Casual Leave (CL)",
      icon: Icons.event_busy_rounded,
      iconBg: Color(0xFFFBDADA),
      status: "REJECTED",
      accentColor: AppColors.rejectedColor,
      dateLabel: "10 Aug 2026",
      tags: ["1.0 Day", "Full Day"],
      reason: "Short notice urgent travel.",
      appliedLabel: "Applied on 09 Aug",
      adminNote: "Insufficient team coverage during Q3 sprint release. "
          "Please reschedule.",
    ),
    const _HistoryItem(
      title: "Earned Leave (EL)",
      icon: Icons.flight_takeoff_rounded,
      iconBg: Color(0xFFFDEBD3),
      status: "PENDING",
      accentColor: AppColors.pendingColor,
      dateLabel: "14 Oct – 16 Oct 2026",
      tags: ["3 Days", "Full Day"],
      reason: "Pre-planned annual family festival visit.",
      appliedLabel: "Applied on 20 Sep",
      cancellable: true,
    ),
    const _HistoryItem(
      title: "Compensatory Off",
      icon: Icons.change_circle_outlined,
      iconBg: Color(0xFFE5E7EB),
      status: "CANCELLED",
      accentColor: AppColors.cancelledColor,
      dateLabel: "04 Jul 2026",
      dateStrikeThrough: true,
      tags: ["1.0 Day", "Full Day"],
      reason: "Self-cancelled: Project deployment moved to weekday.",
      appliedLabel: "Withdrawn on 02 Jul",
    ),
  ];

  _StatusFilter _filter = _StatusFilter.all;

  List<_HistoryItem> get _filteredItems {
    switch (_filter) {
      case _StatusFilter.pending:
        return _items.where((i) => i.status == "PENDING").toList();
      case _StatusFilter.approved:
        return _items.where((i) => i.status == "APPROVED").toList();
      case _StatusFilter.all:
        return _items;
    }
  }

  int _countFor(_StatusFilter filter) {
    switch (filter) {
      case _StatusFilter.pending:
        return _items.where((i) => i.status == "PENDING").length;
      case _StatusFilter.approved:
        return _items.where((i) => i.status == "APPROVED").length;
      case _StatusFilter.all:
        return _items.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    children: [
                      _buildTopBar(context),
                      const SizedBox(height: 16),
                      _buildFilterRow(context),
                      const SizedBox(height: 14),
                      _buildMetaRow(context),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    children: [
                      ..._filteredItems.map(
                            (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildHistoryCard(context, item),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildBottomBar(context),
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
            "Leave History",
            fontSize: 18,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
        ),
        InkWell(
          onTap: () {
            // TODO: open advanced filter sheet
          },
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.tune_rounded, color: AppColors.labelTextColor),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          height: 34,
          width: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: AppColors.whiteColor, size: 18),
        ),
      ],
    );
  }

  // ==================== FILTERS ====================
  Widget _buildFilterRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildFilterChip(
            label: "All",
            count: _countFor(_StatusFilter.all),
            filter: _StatusFilter.all,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterChip(
            label: "Pending",
            count: _countFor(_StatusFilter.pending),
            filter: _StatusFilter.pending,
            color: AppColors.pendingColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterChip(
            label: "Approved",
            count: _countFor(_StatusFilter.approved),
            filter: _StatusFilter.approved,
            color: AppColors.approvedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required _StatusFilter filter,
    required Color color,
  }) {
    final bool selected = _filter == filter;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
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
                height: 7,
                width: 7,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            AppText(
              label,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.whiteColor : AppColors.bodyTextColor,
            ),
            const SizedBox(width: 5),
            AppText(
              "$count",
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.whiteColor : AppColors.labelTextColor,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== META ROW ====================
  Widget _buildMetaRow(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.labelTextColor),
        const SizedBox(width: 6),
        Expanded(
          child: CaptionText("$_fyLabel • ${_items.length} Total Applications"),
        ),
        InkWell(
          onTap: () {
            // TODO: export CSV / PDF
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.ios_share_rounded, size: 14, color: AppColors.primaryColor),
              const SizedBox(width: 4),
              AppText("Export", fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryColor),
            ],
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () {
            // TODO: toggle sort order
          },
          child: const Icon(Icons.swap_vert_rounded, size: 18, color: AppColors.labelTextColor),
        ),
      ],
    );
  }

  // ==================== HISTORY CARD ====================
  Widget _buildHistoryCard(BuildContext context, _HistoryItem item) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: item.accentColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.cardBgColor,
                borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 38,
                        width: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: item.iconBg,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(item.icon, size: 18, color: AppColors.bodyTextColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppText(
                          item.title,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusChip(item.status, item.accentColor),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.labelTextColor),
                      const SizedBox(width: 6),
                      AppText(
                        item.dateLabel,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.labelTextColor,
                        decoration: item.dateStrikeThrough ? TextDecoration.lineThrough : null,
                      ),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: item.tags.map(_buildTagChip).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppText(
                    '"${item.reason}"',
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.bodyTextColor,
                  ),
                  const SizedBox(height: 8),
                  CaptionText(item.appliedLabel),
                  if (item.approvedByLabel != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 13, color: AppColors.approvedColor),
                        const SizedBox(width: 5),
                        AppText(
                          item.approvedByLabel!,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.approvedColor,
                        ),
                      ],
                    ),
                  ],
                  if (item.adminNote != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor.withOpacity(.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 15, color: AppColors.errorColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppText(
                              "Admin Note: ${item.adminNote}",
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (item.cancellable) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: LeaveViewModel.cancelRequest(item)
                        },
                        icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.errorColor),
                        label: AppText(
                          "Cancel Request",
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.errorColor,
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.errorColor.withOpacity(.08),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
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

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.fieldFillColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppText(label, fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.labelTextColor),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 6, width: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          AppText(status, fontSize: 10, fontWeight: FontWeight.w700, color: color),
        ],
      ),
    );
  }

  // ==================== BOTTOM BAR ====================
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, RouteNames.applyLeave),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.whiteColor),
              const SizedBox(width: 8),
              AppText(
                "Request Time Off",
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.whiteColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryItem {
  final String title;
  final IconData icon;
  final Color iconBg;
  final String status;
  final Color accentColor;
  final String dateLabel;
  final bool dateStrikeThrough;
  final List<String> tags;
  final String reason;
  final String appliedLabel;
  final String? approvedByLabel;
  final String? adminNote;
  final bool cancellable;

  const _HistoryItem({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.status,
    required this.accentColor,
    required this.dateLabel,
    this.dateStrikeThrough = false,
    required this.tags,
    required this.reason,
    required this.appliedLabel,
    this.approvedByLabel,
    this.adminNote,
    this.cancellable = false,
  });
}