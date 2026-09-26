import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/errors/failure.dart';
import '../../model/leave_model.dart';
import '../../utils/app_utils.dart';
import '../../viewmodel/leave_viewmodel.dart';
import '../../widget/app_button.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_loader.dart';
import '../../widget/app_text.dart';
import 'leave_ui_helper.dart';

enum _Duration { fullDay, firstHalf, secondHalf }

String _durationApiValue(_Duration d) {
  switch (d) {
    case _Duration.fullDay:
      return "FULL_DAY";
    case _Duration.firstHalf:
      return "FIRST_HALF";
    case _Duration.secondHalf:
      return "SECOND_HALF";
  }
}

class ApplyLeaveScreen extends ConsumerStatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  ConsumerState<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends ConsumerState<ApplyLeaveScreen> {
  static const _maxReasonLength = 200;
  static const _quickReasons = [
    "Personal errand",
    "Medical",
    "Family travel",
    "Festival",
  ];

  final TextEditingController _reasonController = TextEditingController();

  LeaveTypeModel? _selectedType;
  _Duration _duration = _Duration.fullDay;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  bool get _isSingleDay =>
      _startDate.year == _endDate.year &&
          _startDate.month == _endDate.month &&
          _startDate.day == _endDate.day;

  int get _inclusiveDayCount => _endDate.difference(_startDate).inDays + 1;

  double get _totalDays => (_isSingleDay && _duration != _Duration.fullDay)
      ? 0.5
      : _inclusiveDayCount.toDouble();

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  LeaveBalanceModel? _balanceFor(
      List<LeaveBalanceModel> balances,
      int? leaveTypeId,
      ) {
    if (leaveTypeId == null) return null;
    final matches = balances
        .where((b) => b.leaveTypeId == leaveTypeId)
        .toList();
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<void> _submit(List<LeaveBalanceModel> balances) async {
    if (_selectedType == null) {
      AppUtils.showErrorSnackbar(context, "Please select a leave type.");
      return;
    }
    final balance = _balanceFor(balances, _selectedType!.leaveTypeId);
    if (balance != null && _totalDays > balance.remainingDays) {
      AppUtils.showErrorSnackbar(
        context,
        "You only have ${balance.remainingDays} day(s) left for this leave type.",
      );
      return;
    }

    final success = await ref
        .read(applyLeaveViewModelProvider.notifier)
        .submit(
      leaveTypeId: _selectedType!.leaveTypeId,
      startDate: _startDate,
      endDate: _endDate,
      leaveDurationType: _durationApiValue(_duration),
      reason: _reasonController.text,
    );

    if (!mounted) return;

    if (success) {
      AppUtils.showSnackbar(context, "Leave request submitted.");
      Navigator.of(context).pop();
    } else {
      final error = ref.read(applyLeaveViewModelProvider).error;
      AppUtils.showErrorSnackbar(
        context,
        error is Failure
            ? error.message
            : "Couldn't submit your request. Please try again.",
      );
    }
  }

  // ==================== DATE PICKING (table_calendar) ====================
  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final firstDate = DateTime.now();
    final picked = await _showCalendarSheet(
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked.isBefore(_startDate) ? _startDate : picked;
      }
    });
  }

  Future<DateTime?> _showCalendarSheet({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CalendarPickerSheet(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }

  Future<void> _pickLeaveType(List<LeaveTypeModel> types) async {
    final picked = await showModalBottomSheet<LeaveTypeModel>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          decoration: const BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const AppText(
                "Select Leave Type",
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 10),
              ...types.map((t) {
                final color = LeaveUiHelper.colorForCode(t.code);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withOpacity(.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LeaveUiHelper.iconForCode(t.code),
                      color: color,
                    ),
                  ),
                  title: AppText(
                    t.name,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  subtitle: CaptionText(
                    "${t.defaultAnnualDays.toStringAsFixed(0)} days/year",
                  ),
                  onTap: () => Navigator.pop(sheetContext, t),
                );
              }),
            ],
          ),
        );
      },
    );

    if (picked != null) setState(() => _selectedType = picked);
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(leaveTypesProvider);
    final balanceAsync = ref.watch(leaveBalanceViewModelProvider);
    final applyState = ref.watch(applyLeaveViewModelProvider);
    final isSubmitting = applyState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: (typesAsync.isLoading || balanceAsync.isLoading)
                ? const _ApplyLeaveSkeleton()
                : (typesAsync.hasError || balanceAsync.hasError)
                ? _buildErrorState(
              typesAsync.hasError
                  ? typesAsync.error!
                  : balanceAsync.error!,
                  () {
                ref.refresh(leaveTypesProvider);
                ref
                    .read(leaveBalanceViewModelProvider.notifier)
                    .refresh();
              },
            )
                : _buildForm(
              context,
              typesAsync.value!,
              balanceAsync.value!,
              isSubmitting,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
      BuildContext context,
      List<LeaveTypeModel> types,
      List<LeaveBalanceModel> balances,
      bool isSubmitting,
      ) {
    // Ensure a default selection once types load.
    if (_selectedType == null && types.isNotEmpty) {
      _selectedType = types.first;
    }
    final balance = _balanceFor(balances, _selectedType?.leaveTypeId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _buildTopBar(context),
        const SizedBox(height: 10),
        if (balance != null) _buildBalanceHero(balance),
        const SizedBox(height: 10),
        _buildLabel("Leave Type", required: true),
        const SizedBox(height: 10),
        _buildLeaveTypeSelector(types, balance),
        const SizedBox(height: 22),
        _buildDatesHeader(context),
        const SizedBox(height: 10),
        _buildDateRow(context),
        const SizedBox(height: 22),
        _buildLabel("Duration", trailing: "Applies to single-day leave"),
        const SizedBox(height: 10),
        _buildDurationSelector(),
        const SizedBox(height: 22),
        _buildComputationCard(balance),
        const SizedBox(height: 22),
        _buildLabel(
          "Reason for Leave",
          optional: true,
          trailing: "${_reasonController.text.length}/$_maxReasonLength",
        ),
        const SizedBox(height: 10),
        _buildReasonField(),
        const SizedBox(height: 10),
        _buildQuickReasonChips(),
        const SizedBox(height: 22),
        _buildSubmitButton(balances, isSubmitting),
        // const SizedBox(height: 10),
        // _buildSubmitCaption(),
      ],
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
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.headlineTextColor,
            ),
          ),
        ),
        const Expanded(
          child: AppText(
            "Apply for Leave",
            fontSize: 15,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 32),
      ],
    );
  }

  // ==================== BALANCE HERO ====================
  Widget _buildBalanceHero(LeaveBalanceModel balance) {
    final percentLeft = balance.allocatedDays == 0
        ? 0.0
        : balance.remainingDays / balance.allocatedDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
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
          Container(
            height: 46,
            width: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.whiteColor.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              color: AppColors.whiteColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  "AVAILABLE BALANCE",
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.whiteColor.withOpacity(.75),
                ),
                const SizedBox(height: 4),
                AppText(
                  "${balance.remainingDays.toStringAsFixed(0)} Days Left",
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteColor,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.whiteColor.withOpacity(.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    value: percentLeft.clamp(0, 1),
                    strokeWidth: 2.2,
                    backgroundColor: AppColors.whiteColor.withOpacity(.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.whiteColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AppText(
                  "${(percentLeft * 100).round()}% Left",
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LABEL HELPERS ====================
  Widget _buildLabel(
      String text, {
        bool required = false,
        bool optional = false,
        String? trailing,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            AppText(text, fontSize: 12, fontWeight: FontWeight.w600),
            if (required)
              const AppText(
                " *",
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.errorColor,
              ),
            if (optional)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: CaptionText("(Optional)"),
              ),
          ],
        ),
        if (trailing != null) CaptionText(trailing),
      ],
    );
  }

  // ==================== LEAVE TYPE ====================
  Widget _buildLeaveTypeSelector(
      List<LeaveTypeModel> types,
      LeaveBalanceModel? balance,
      ) {
    final selected = _selectedType;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _pickLeaveType(types),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                selected != null
                    ? LeaveUiHelper.iconForCode(selected.code)
                    : Icons.beach_access_rounded,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    selected?.name ?? "Select leave type",
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 2),
                  CaptionText(
                    balance != null
                        ? "${balance.remainingDays.toStringAsFixed(0)} of ${balance.allocatedDays.toStringAsFixed(0)} days available"
                        : "Tap to choose",
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.labelTextColor,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DATES ====================
  Widget _buildDatesHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLabel("Select Dates", required: true),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 14,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 4),
            AppText(
              _isSingleDay ? "Single-day selected" : "Multi-day selected",
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDateBox(
            "START DATE",
            _startDate,
            Icons.calendar_today_rounded,
                () => _pickDate(isStart: true),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            height: 30,
            width: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 15,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        Expanded(
          child: _buildDateBox(
            "END DATE",
            _endDate,
            Icons.event_available_rounded,
                () => _pickDate(isStart: false),
          ),
        ),
      ],
    );
  }

  Widget _buildDateBox(
      String label,
      DateTime date,
      IconData icon,
      VoidCallback onTap,
      ) {
    const weekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final weekday = weekdays[date.weekday - 1];
    final dateLabel = "${date.day} ${months[date.month - 1]} ${date.year}";

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
                Icon(icon, size: 13, color: AppColors.primaryColor),
                const SizedBox(width: 5),
                AppText(
                  label,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .6,
                  color: AppColors.labelTextColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            AppText(dateLabel, fontSize: 12, fontWeight: FontWeight.w600),
            const SizedBox(height: 2),
            CaptionText(weekday),
          ],
        ),
      ),
    );
  }

  // ==================== DURATION (compact) ====================
  Widget _buildDurationSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildDurationOption(
            title: "Full Day",
            subtitle: "Full Shift",
            value: _Duration.fullDay,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDurationOption(
            title: "First Half",
            subtitle: "Morning",
            value: _Duration.firstHalf,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDurationOption(
            title: "Second Half",
            subtitle: "Afternoon",
            value: _Duration.secondHalf,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationOption({
    required String title,
    required String subtitle,
    required _Duration value,
  }) {
    final bool selected = _duration == value;
    final bool enabled = _isSingleDay || value == _Duration.fullDay;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? () => setState(() => _duration = value) : null,
      child: Opacity(
        opacity: enabled ? 1 : .4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryColor : AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primaryColor : AppColors.borderColor,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value == _Duration.fullDay)
                Icon(
                  Icons.check_circle_rounded,
                  size: 13,
                  color: selected
                      ? AppColors.whiteColor
                      : AppColors.placeholderColor,
                ),
              if (value == _Duration.fullDay) const SizedBox(height: 3),
              AppText(
                title,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.whiteColor
                    : AppColors.headlineTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 1),
              AppText(
                subtitle,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: selected
                    ? AppColors.whiteColor.withOpacity(.85)
                    : AppColors.labelTextColor,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== COMPUTATION ====================
  Widget _buildComputationCard(LeaveBalanceModel? balance) {
    final postApproval = balance != null
        ? (balance.remainingDays - _totalDays).clamp(0, balance.allocatedDays)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fieldFillColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: 6),
                  AppText(
                    "Leave Computation",
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppText(
                  "${_totalDays.toStringAsFixed(_totalDays % 1 == 0 ? 0 : 1)} Day Total",
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CaptionText("Post-Approval Balance"),
              AppText(
                postApproval != null
                    ? "${postApproval.toStringAsFixed(postApproval % 1 == 0 ? 0 : 1)} Days Left"
                    : "—",
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== REASON ====================
  Widget _buildReasonField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: TextField(
        controller: _reasonController,
        maxLength: _maxReasonLength,
        maxLines: 3,
        style: const TextStyle(
          fontFamily: "Poppins",
          fontSize: 14,
          color: AppColors.headlineTextColor,
        ),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(14),
          hintText:
          "e.g. Family function, personal appointment,\nmedical recovery...",
          hintStyle: TextStyle(
            fontFamily: "Poppins",
            fontSize: 13,
            color: AppColors.placeholderColor,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReasonChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _quickReasons.map((r) {
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() {
            _reasonController.text = r;
            _reasonController.selection = TextSelection.collapsed(
              offset: r.length,
            );
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.fieldFillColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AppText(
              r,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.bodyTextColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==================== SUBMIT ====================
  Widget _buildSubmitButton(
      List<LeaveBalanceModel> balances,
      bool isSubmitting,
      ) {
    return AppButton(
      text: isSubmitting ? "Submitting..." : "Submit Leave Request",
      icon: Icons.send_rounded,
      gradient: AppColors.primaryGradient,
      onTap: isSubmitting ? null : () => _submit(balances),
    );
  }
  //
  // Widget _buildSubmitCaption() {
  //   return const Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       Icon(
  //         Icons.schedule_rounded,
  //         size: 13,
  //         color: AppColors.placeholderColor,
  //       ),
  //       SizedBox(width: 6),
  //       CaptionText(
  //         "Requests are typically reviewed by management within 24 hours.",
  //       ),
  //     ],
  //   );
  // }

  // ==================== ERROR / SKELETON ====================
  Widget _buildErrorState(Object error, VoidCallback onRetry) {
    final message = error is Failure
        ? error.message
        : "Couldn't load leave data.";
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 32,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: 10),
            AppText(
              message,
              fontSize: 13,
              color: AppColors.labelTextColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 140,
              child: AppButton(
                text: "Retry",
                icon: Icons.refresh_rounded,
                onTap: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplyLeaveSkeleton extends StatelessWidget {
  const _ApplyLeaveSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        AppSkeletonBox(height: 32, width: 180, borderRadius: 8),
        const SizedBox(height: 20),
        AppSkeletonBox(height: 96, borderRadius: 20),
        const SizedBox(height: 22),
        AppSkeletonBox(height: 66, borderRadius: 16),
        const SizedBox(height: 22),
        AppSkeletonBox(height: 130, borderRadius: 14),
        const SizedBox(height: 22),
        AppSkeletonBox(height: 84, borderRadius: 16),
        const SizedBox(height: 22),
        AppSkeletonBox(height: 90, borderRadius: 14),
      ],
    );
  }
}

// ==================== CALENDAR PICKER SHEET (table_calendar) ====================
class _CalendarPickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _CalendarPickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_CalendarPickerSheet> createState() => _CalendarPickerSheetState();
}

class _CalendarPickerSheetState extends State<_CalendarPickerSheet> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _selectedDay = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.borderColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const AppText(
            "Select Date",
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 6),
          TableCalendar(
            firstDay: widget.firstDate,
            lastDay: widget.lastDate,
            focusedDay: _focusedDay,
            currentDay: DateTime.now(),
            calendarFormat: CalendarFormat.month,
            availableGestures: AvailableGestures.horizontalSwipe,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) =>
            _selectedDay != null && _isSameDay(_selectedDay!, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: AppColors.primaryColor,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryColor,
              ),
              titleTextStyle: TextStyle(
                fontFamily: "Poppins",
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.headlineTextColor,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontFamily: "Poppins",
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.labelTextColor,
              ),
              weekendStyle: TextStyle(
                fontFamily: "Poppins",
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.labelTextColor,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(4),
              defaultTextStyle: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.headlineTextColor,
              ),
              weekendTextStyle: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.headlineTextColor,
              ),
              disabledTextStyle: TextStyle(
                fontFamily: "Poppins",
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.placeholderColor.withOpacity(.5),
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.whiteColor,
              ),
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            text: "Confirm Date",
            icon: Icons.check_rounded,
            gradient: AppColors.primaryGradient,
            onTap: _selectedDay == null
                ? null
                : () => Navigator.pop(context, _selectedDay),
          ),
        ],
      ),
    );
  }
}