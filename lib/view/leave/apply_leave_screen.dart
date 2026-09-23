import 'package:flutter/material.dart';
import '../../widget/app_button.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';

/// AttendEase — "Apply for Leave" form.
/// Leave type + date + duration selection, live computation preview,
/// optional reason with quick-fill chips, and contextual notices
/// before submit.
class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

enum _Duration { fullDay, firstHalf, secondHalf }

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  static const _maxReasonLength = 200;
  static const _quickReasons = [
    "Personal errand",
    "Medical",
    "Family travel",
    "Festival",
  ];

  final TextEditingController _reasonController = TextEditingController();

  String _leaveType = "Casual Leave (CL)";
  int _allocatedDays = 12;
  int _usedDays = 3;
  _Duration _duration = _Duration.fullDay;
  DateTime _startDate = DateTime(2026, 9, 28);
  DateTime _endDate = DateTime(2026, 9, 28);

  int get _daysLeft => _allocatedDays - _usedDays;
  bool get _isSingleDay => _startDate.year == _endDate.year &&
      _startDate.month == _endDate.month &&
      _startDate.day == _endDate.day;
  double get _totalDays => _isSingleDay && _duration != _Duration.fullDay ? 0.5 : 1.0;

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
                const SizedBox(height: 16),
                _buildAllowanceRow(context),
                const SizedBox(height: 14),
                _buildBalanceHero(context),
                const SizedBox(height: 22),
                _buildLabel("Leave Type", required: true),
                const SizedBox(height: 10),
                _buildLeaveTypeSelector(context),
                const SizedBox(height: 8),
                _buildHintRow(Icons.swap_horiz_rounded,
                    "Tap to toggle category (Casual, Sick, Earned, Comp-off)"),
                const SizedBox(height: 22),
                _buildDatesHeader(context),
                const SizedBox(height: 10),
                _buildDateRow(context),
                const SizedBox(height: 10),
                _buildQuickDateChips(context),
                const SizedBox(height: 22),
                _buildLabel("Duration", trailing: "Applies to single-day leave"),
                const SizedBox(height: 10),
                _buildDurationSelector(context),
                const SizedBox(height: 22),
                _buildComputationCard(context),
                const SizedBox(height: 22),
                _buildLabel(
                  "Reason for Leave",
                  optional: true,
                  trailing: "${_reasonController.text.length}/$_maxReasonLength",
                ),
                const SizedBox(height: 10),
                _buildReasonField(context),
                const SizedBox(height: 10),
                _buildQuickReasonChips(context),
                const SizedBox(height: 16),
                _buildInfoBanner(context),
                const SizedBox(height: 12),
                _buildCollisionCheckBanner(context),
                const SizedBox(height: 22),
                _buildSubmitButton(context),
                const SizedBox(height: 10),
                _buildSubmitCaption(context),
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
          onTap: () {
            // TODO: show leave-policy help sheet
          },
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.help_outline_rounded, color: AppColors.labelTextColor),
          ),
        ),
      ],
    );
  }

  Widget _buildAllowanceRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              height: 8,
              width: 8,
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            AppText(
              "Casual Allowance: ${_daysLeft}d Left",
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.bodyTextColor,
            ),
          ],
        ),
      ],
    );
  }

  // ==================== BALANCE HERO ====================
  Widget _buildBalanceHero(BuildContext context) {
    final double percentLeft = _allocatedDays == 0 ? 0 : _daysLeft / _allocatedDays;

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
                  "AVAILABLE BALANCE",
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.whiteColor.withOpacity(.75),
                ),
                const SizedBox(height: 4),
                AppText(
                  "Casual Leave ($_daysLeft Days)",
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
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
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.whiteColor),
                  ),
                ),
                const SizedBox(width: 6),
                AppText(
                  "${(percentLeft * 100).round()}% Left",
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
  Widget _buildLabel(String text, {bool required = false, bool optional = false, String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            AppText(text, fontSize: 14, fontWeight: FontWeight.w700),
            if (required)
              AppText(" *", fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.errorColor),
            if (optional)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: CaptionText("(Optional)"),
              ),
          ],
        ),
        if (trailing != null) CaptionText(trailing),
      ],
    );
  }

  Widget _buildHintRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.placeholderColor),
        const SizedBox(width: 6),
        Expanded(child: CaptionText(text)),
      ],
    );
  }

  // ==================== LEAVE TYPE ====================
  Widget _buildLeaveTypeSelector(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // TODO: open leave-type picker sheet, update _leaveType/_allocatedDays
      },
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
              child: const Icon(Icons.beach_access_rounded, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppText(_leaveType, fontSize: 15, fontWeight: FontWeight.w500),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successColor.withOpacity(.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AppText(
                          "Paid",
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.successColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  CaptionText("$_daysLeft of $_allocatedDays days allocated available"),
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
        _buildLabel("Select Dates", required: true),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.primaryColor),
                const SizedBox(width: 4),
                AppText(
                  _isSingleDay ? "Single-day selected" : "Multi-day selected",
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildDateBox("START DATE", _startDate, Icons.calendar_today_rounded)),
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
            child: const Icon(Icons.arrow_forward_rounded, size: 15, color: AppColors.primaryColor),
          ),
        ),
        Expanded(child: _buildDateBox("END DATE", _endDate, Icons.event_available_rounded)),
      ],
    );
  }

  Widget _buildDateBox(String label, DateTime date, IconData icon) {
    const weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    final weekday = weekdays[date.weekday - 1];
    final dateLabel = "${date.day} ${months[date.month - 1]} ${date.year}";

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        // TODO: showDatePicker and update state
      },
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
            AppText(dateLabel, fontSize: 14, fontWeight: FontWeight.w700),
            const SizedBox(height: 2),
            CaptionText(weekday),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateChips(BuildContext context) {
    final chips = ["Today", "Tomorrow", "Next Monday", "Custom Range"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((label) {
          final bool selected = label == "Today"; // TODO: derive from real state
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) {
                // TODO: update _startDate/_endDate
              },
              labelStyle: TextStyle(
                fontFamily: "Poppins",
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.whiteColor : AppColors.bodyTextColor,
              ),
              selectedColor: AppColors.primaryColor,
              backgroundColor: AppColors.fieldFillColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== DURATION ====================
  Widget _buildDurationSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDurationOption(
            title: "Full Day",
            subtitle: "Full Shift",
            value: _Duration.fullDay,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDurationOption(
            title: "First Half",
            subtitle: "09:00 - 13:30",
            value: _Duration.firstHalf,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDurationOption(
            title: "Second Half",
            subtitle: "13:30 - 18:00",
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
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _duration = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.borderColor,
          ),
        ),
        child: Column(
          children: [
            if (value == _Duration.fullDay)
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: selected ? AppColors.whiteColor : AppColors.placeholderColor,
              ),
            if (value == _Duration.fullDay) const SizedBox(height: 4),
            AppText(
              title,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.whiteColor : AppColors.headlineTextColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            AppText(
              subtitle,
              fontSize: 11,
              color: selected ? AppColors.whiteColor.withOpacity(.85) : AppColors.labelTextColor,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== COMPUTATION ====================
  Widget _buildComputationCard(BuildContext context) {
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
              Row(
                children: [
                  const Icon(Icons.calculate_outlined, size: 16, color: AppColors.primaryColor),
                  const SizedBox(width: 6),
                  AppText("Leave Computation", fontSize: 13, fontWeight: FontWeight.w700),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppText(
                  "$_totalDays Day Total",
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildComputationRow(
            "Post-Approval Balance",
            "${(_daysLeft - _totalDays).clamp(0, _allocatedDays)} Days Left",
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CaptionText("Designated Approver"),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 11,
                    backgroundColor: AppColors.primaryColor,
                    child: AppText("DV", fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.whiteColor),
                  ),
                  const SizedBox(width: 6),
                  AppText("Devon Vance (Lead)", fontSize: 12, fontWeight: FontWeight.w700),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComputationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CaptionText(label),
        AppText(value, fontSize: 13, fontWeight: FontWeight.w700),
      ],
    );
  }

  // ==================== REASON ====================
  Widget _buildReasonField(BuildContext context) {
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
        style: const TextStyle(fontFamily: "Poppins", fontSize: 14, color: AppColors.headlineTextColor),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(14),
          hintText: "e.g. Family function, personal appointment,\nmedical recovery...",
          hintStyle: TextStyle(fontFamily: "Poppins", fontSize: 13, color: AppColors.placeholderColor),
        ),
      ),
    );
  }

  Widget _buildQuickReasonChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _quickReasons.map((r) {
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() {
            _reasonController.text = r;
            _reasonController.selection = TextSelection.collapsed(offset: r.length);
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

  // ==================== NOTICES ====================
  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign_outlined, size: 18, color: AppColors.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText("Upcoming Holiday Notice", fontSize: 13, fontWeight: FontWeight.w700),
                const SizedBox(height: 3),
                AppText(
                  "02 Oct (Gandhi Jayanti) is a national holiday. For "
                      "extended long-weekend plans, kindly submit requests "
                      "at least 3 workdays in advance.",
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

  Widget _buildCollisionCheckBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.successColor.withOpacity(.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.successColor),
          const SizedBox(width: 10),
          AppText(
            "Schedule Collision Check: Pass",
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.successColor,
          ),
          const Spacer(),
          CaptionText("No overlapping shifts"),
        ],
      ),
    );
  }

  // ==================== SUBMIT ====================
  Widget _buildSubmitButton(BuildContext context) {
    return AppButton(
      text: "Submit Leave Request",
      icon: Icons.send_rounded,
      gradient: AppColors.primaryGradient,
      onTap: () {
        // TODO: LeaveViewModel.submit(context)
      },
    );
  }

  Widget _buildSubmitCaption(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.schedule_rounded, size: 13, color: AppColors.placeholderColor),
        const SizedBox(width: 6),
        CaptionText("Requests are typically reviewed by management within 24 hours."),
      ],
    );
  }
}