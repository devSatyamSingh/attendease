import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:table_calendar/table_calendar.dart';
import '../../core/errors/failure.dart';
import '../../localization/lanaguge_provider.dart';
import '../../model/leave_model.dart';
import '../../utils/app_topbar.dart';
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

// ==================== HELPERS ====================
bool _isRtl(BuildContext c) => Directionality.of(c) == TextDirection.rtl;

/// Number / percent ka order Urdu me ulta na ho.
String _ltrIso(String s) => '\u2066$s\u2069';

/// 3.0 -> "3", 2.5 -> "2.5"
String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

/// TextField / calendar jaise raw TextStyle wale widgets ke liye font.
String _fontFor(BuildContext c) =>
    Localizations.localeOf(c).languageCode == 'ur' ? 'NotoNastaliqUrdu' : 'Poppins';

class ApplyLeaveScreen extends ConsumerStatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  ConsumerState<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends ConsumerState<ApplyLeaveScreen> {
  static const _maxReasonLength = 200;

  /// Sirf translation keys. Chip tap par translated text reason me jaata hai.
  static const _quickReasonKeys = [
    'apply_leave.reason_personal',
    'apply_leave.reason_medical',
    'apply_leave.reason_family',
    'apply_leave.reason_festival',
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

  double get _totalDays =>
      (_isSingleDay && _duration != _Duration.fullDay) ? 0.5 : _inclusiveDayCount.toDouble();

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

  LeaveBalanceModel? _balanceFor(List<LeaveBalanceModel> balances, int? leaveTypeId) {
    if (leaveTypeId == null) return null;
    final matches = balances.where((b) => b.leaveTypeId == leaveTypeId).toList();
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<void> _submit(List<LeaveBalanceModel> balances) async {
    if (_selectedType == null) {
      AppUtils.showErrorSnackbar(context, 'apply_leave.err_select_type'.tr());
      return;
    }
    final balance = _balanceFor(balances, _selectedType!.leaveTypeId);
    if (balance != null && _totalDays > balance.remainingDays) {
      AppUtils.showErrorSnackbar(
        context,
        'apply_leave.err_balance'.tr(args: [_fmt(balance.remainingDays)]),
      );
      return;
    }

    final success = await ref.read(applyLeaveViewModelProvider.notifier).submit(
      leaveTypeId: _selectedType!.leaveTypeId,
      startDate: _startDate,
      endDate: _endDate,
      leaveDurationType: _durationApiValue(_duration),
      reason: _reasonController.text,
    );

    if (!mounted) return;

    if (success) {
      AppUtils.showSnackbar(context, 'apply_leave.success'.tr());
      Navigator.of(context).pop();
    } else {
      final error = ref.read(applyLeaveViewModelProvider).error;
      AppUtils.showErrorSnackbar(
        context,
        error is Failure ? error.message : 'apply_leave.err_submit'.tr(),
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
              AppText('apply_leave.select_type_title'.tr(), fontSize: 15, fontWeight: FontWeight.w600),
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
                    child: Icon(LeaveUiHelper.iconForCode(t.code), color: color),
                  ),
                  // Leave type ka naam API se aata hai, waisa hi dikhega
                  title: AppText(t.name, fontSize: 14, fontWeight: FontWeight.w600),
                  subtitle: CaptionText(
                    'apply_leave.days_per_year'.tr(args: [t.defaultAnnualDays.toStringAsFixed(0)]),
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
    // Language badalte hi ye screen turant rebuild ho
    ref.watch(languageProvider);

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
              typesAsync.hasError ? typesAsync.error! : balanceAsync.error!,
                  () {
                ref.refresh(leaveTypesProvider);
                ref.read(leaveBalanceViewModelProvider.notifier).refresh();
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
    // Types load hone par default selection
    if (_selectedType == null && types.isNotEmpty) {
      _selectedType = types.first;
    }
    final balance = _balanceFor(balances, _selectedType?.leaveTypeId);

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
      children: [
        AppTopBar(title: 'apply_leave.title'.tr()),
        const SizedBox(height: 10),
        if (balance != null) _buildBalanceHero(balance),
        const SizedBox(height: 10),
        _buildLabel('apply_leave.leave_type'.tr(), required: true),
        const SizedBox(height: 10),
        _buildLeaveTypeSelector(types, balance),
        const SizedBox(height: 22),
        _buildDatesHeader(context),
        const SizedBox(height: 10),
        _buildDateRow(context),
        const SizedBox(height: 22),
        _buildLabel('apply_leave.duration'.tr(), trailing: 'apply_leave.duration_hint'.tr()),
        const SizedBox(height: 10),
        _buildDurationSelector(),
        const SizedBox(height: 22),
        _buildComputationCard(balance),
        const SizedBox(height: 22),
        _buildLabel(
          'apply_leave.reason'.tr(),
          optional: true,
          trailing: _ltrIso("${_reasonController.text.length}/$_maxReasonLength"),
        ),
        const SizedBox(height: 10),
        _buildReasonField(context),
        const SizedBox(height: 10),
        _buildQuickReasonChips(),
        const SizedBox(height: 22),
        _buildSubmitButton(balances, isSubmitting),
      ],
    );
  }

  // ==================== BALANCE HERO ====================
  Widget _buildBalanceHero(LeaveBalanceModel balance) {
    final percentLeft =
    balance.allocatedDays == 0 ? 0.0 : balance.remainingDays / balance.allocatedDays;

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
            child: const Icon(Icons.wb_sunny_outlined, color: AppColors.whiteColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'apply_leave.available_balance'.tr(),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.whiteColor.withOpacity(.75),
                ),
                const SizedBox(height: 4),
                AppText(
                  'leaves.days_left'.tr(args: [_fmt(balance.remainingDays)]),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteColor,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.whiteColor),
                  ),
                ),
                const SizedBox(width: 6),
                AppText(
                  'apply_leave.percent_left'.tr(args: [(percentLeft * 100).round().toString()]),
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
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: AppText(text, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (required)
                const AppText(
                  " *",
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.errorColor,
                ),
              if (optional)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: CaptionText('apply_leave.optional'.tr()),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: CaptionText(trailing, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ],
    );
  }

  // ==================== LEAVE TYPE ====================
  Widget _buildLeaveTypeSelector(List<LeaveTypeModel> types, LeaveBalanceModel? balance) {
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
                    selected?.name ?? 'apply_leave.select_leave_type_hint'.tr(),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 2),
                  CaptionText(
                    balance != null
                        ? 'apply_leave.of_available'.tr(
                      args: [_fmt(balance.remainingDays), _fmt(balance.allocatedDays)],
                    )
                        : 'apply_leave.tap_to_choose'.tr(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.labelTextColor),
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
        Flexible(child: _buildLabel('apply_leave.select_dates'.tr(), required: true)),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            AppText(
              _isSingleDay
                  ? 'apply_leave.single_selected'.tr()
                  : 'apply_leave.multi_selected'.tr(),
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
            context,
            'apply_leave.start_date'.tr(),
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
            child: Icon(
              _isRtl(context) ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
              size: 15,
              color: AppColors.primaryColor,
              textDirection: TextDirection.ltr, // double-mirroring roko
            ),
          ),
        ),
        Expanded(
          child: _buildDateBox(
            context,
            'apply_leave.end_date'.tr(),
            _endDate,
            Icons.event_available_rounded,
                () => _pickDate(isStart: false),
          ),
        ),
      ],
    );
  }

  Widget _buildDateBox(
      BuildContext context,
      String label,
      DateTime date,
      IconData icon,
      VoidCallback onTap,
      ) {
    // Hardcoded weekday/month lists hata di: ab selected language me aayenge
    final locale = context.locale.toString();
    final weekday = DateFormat("EEEE", locale).format(date);
    final dateLabel = DateFormat("d MMM yyyy", locale).format(date);

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
                Flexible(
                  child: AppText(
                    label,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .6,
                    color: AppColors.labelTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
            title: 'leaves.duration_full_day'.tr(),
            subtitle: 'apply_leave.full_shift'.tr(),
            value: _Duration.fullDay,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDurationOption(
            title: 'leaves.duration_first_half'.tr(),
            subtitle: 'apply_leave.morning'.tr(),
            value: _Duration.firstHalf,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDurationOption(
            title: 'leaves.duration_second_half'.tr(),
            subtitle: 'apply_leave.afternoon'.tr(),
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
                  color: selected ? AppColors.whiteColor : AppColors.placeholderColor,
                ),
              if (value == _Duration.fullDay) const SizedBox(height: 3),
              AppText(
                title,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.whiteColor : AppColors.headlineTextColor,
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
        ? (balance.remainingDays - _totalDays).clamp(0, balance.allocatedDays).toDouble()
        : null;

    final totalLabel = _totalDays == 1
        ? 'apply_leave.total_one'.tr(args: [_fmt(_totalDays)])
        : 'apply_leave.total_many'.tr(args: [_fmt(_totalDays)]);

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
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calculate_outlined, size: 16, color: AppColors.primaryColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: AppText(
                        'apply_leave.computation'.tr(),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppText(
                  totalLabel,
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
              Flexible(child: CaptionText('apply_leave.post_balance'.tr())),
              const SizedBox(width: 8),
              AppText(
                postApproval != null
                    ? 'leaves.days_left'.tr(args: [_fmt(postApproval)])
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
  Widget _buildReasonField(BuildContext context) {
    final font = _fontFor(context);
    final isUrdu = font == 'NotoNastaliqUrdu';

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
        style: TextStyle(
          fontFamily: font,
          fontSize: 14,
          height: isUrdu ? 1.7 : null,
          color: AppColors.headlineTextColor,
        ),
        decoration: InputDecoration(
          counterText: "",
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
          hintText: 'apply_leave.reason_hint'.tr(),
          hintStyle: TextStyle(
            fontFamily: font,
            fontSize: 13,
            height: isUrdu ? 1.7 : null,
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
      children: _quickReasonKeys.map((key) {
        final text = key.tr();
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() {
            _reasonController.text = text;
            _reasonController.selection = TextSelection.collapsed(offset: text.length);
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.fieldFillColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AppText(
              text,
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
  Widget _buildSubmitButton(List<LeaveBalanceModel> balances, bool isSubmitting) {
    return AppButton(
      text: isSubmitting ? 'apply_leave.submitting'.tr() : 'apply_leave.submit'.tr(),
      icon: Icons.send_rounded,
      gradient: AppColors.primaryGradient,
      onTap: isSubmitting ? null : () => _submit(balances),
    );
  }

  // ==================== ERROR ====================
  Widget _buildErrorState(Object error, VoidCallback onRetry) {
    final message = error is Failure ? error.message : 'apply_leave.err_load'.tr();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.errorColor),
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
                text: 'common.retry'.tr(),
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

// ==================== SKELETON ====================
class _ApplyLeaveSkeleton extends StatelessWidget {
  const _ApplyLeaveSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
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
    final font = _fontFor(context);
    final isUrdu = font == 'NotoNastaliqUrdu';
    final locale = context.locale.toString();

    TextStyle style({
      double size = 12,
      Color color = AppColors.headlineTextColor,
      FontWeight weight = FontWeight.w600,
    }) =>
        TextStyle(
          fontFamily: font,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: isUrdu ? 1.5 : null,
        );

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + MediaQuery.of(context).padding.bottom),
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
          AppText('apply_leave.select_date'.tr(), fontSize: 15, fontWeight: FontWeight.w600),
          const SizedBox(height: 6),

          // Calendar grid hamesha LTR (Mon..Sun left to right, prev/next arrows sahi side)
          // Month/weekday ke naam locale se translate hote hain.
          Directionality(
            textDirection: TextDirection.ltr,
            child: TableCalendar(
              locale: locale,
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
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.primaryColor,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primaryColor,
                ),
                titleTextStyle: style(size: 13),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: style(size: 11, color: AppColors.labelTextColor),
                weekendStyle: style(size: 11, color: AppColors.labelTextColor),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                cellMargin: const EdgeInsets.all(4),
                defaultTextStyle: style(),
                weekendTextStyle: style(),
                disabledTextStyle: style(color: AppColors.placeholderColor.withOpacity(.5)),
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: style(color: AppColors.primaryColor),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: style(color: AppColors.whiteColor),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            text: 'apply_leave.confirm_date'.tr(),
            icon: Icons.check_rounded,
            gradient: AppColors.primaryGradient,
            onTap: _selectedDay == null ? null : () => Navigator.pop(context, _selectedDay),
          ),
        ],
      ),
    );
  }
}