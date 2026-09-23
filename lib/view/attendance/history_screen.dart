import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';


class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

enum _AttendanceStatus { working, onTime, late, missingCheckout }

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime _selectedMonth = DateTime(2024, 10);
  DateTime _focusedCalendarDay = DateTime(2024, 10, 24);
  DateTime? _selectedCalendarDay = DateTime(2024, 10, 24);

  // ---- Replace with the API response for `_selectedMonth` ----
  static final List<_DailyRecord> _demoRecords = [
    _DailyRecord(
      date: DateTime(2024, 10, 24),
      inTime: "10:08 AM",
      outTime: null,
      workedLabel: "3h 42m",
      status: _AttendanceStatus.working,
    ),
    _DailyRecord(
      date: DateTime(2024, 10, 23),
      inTime: "09:02 AM",
      outTime: "06:14 PM",
      workedLabel: "8h 42m",
      status: _AttendanceStatus.onTime,
    ),
    _DailyRecord(
      date: DateTime(2024, 10, 22),
      inTime: "08:55 AM",
      outTime: "05:58 PM",
      workedLabel: "8h 03m",
      status: _AttendanceStatus.onTime,
    ),
    _DailyRecord(
      date: DateTime(2024, 10, 21),
      inTime: "09:42 AM",
      outTime: "06:45 PM",
      workedLabel: "8h 03m",
      status: _AttendanceStatus.late,
      lateMinutes: 12,
    ),
    _DailyRecord(
      date: DateTime(2024, 10, 18),
      inTime: "09:15 AM",
      outTime: null,
      workedLabel: "4h 15m",
      status: _AttendanceStatus.missingCheckout,
    ),
    _DailyRecord(
      date: DateTime(2024, 10, 17),
      inTime: "08:58 AM",
      outTime: "06:05 PM",
      workedLabel: "8h 07m",
      status: _AttendanceStatus.onTime,
    ),
  ];

  List<_DailyRecord> get _records => _demoRecords; // TODO: filter by _selectedMonth via API

  int get _presentCount =>
      _records.where((r) => r.status != _AttendanceStatus.missingCheckout).length;
  int get _lateCount => _records.where((r) => r.status == _AttendanceStatus.late).length;
  int get _missingCount =>
      _records.where((r) => r.status == _AttendanceStatus.missingCheckout).length;

  static const _onTimeRate = "95.6%";
  static const _onTimeDelta = "+2.4% better than September";

  void _shiftMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    // TODO: refetch _records for the new month from the API
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
                const SizedBox(height: 18),
                _buildOverviewHeader(context),
                const SizedBox(height: 14),
                _buildMonthScroller(context),
                const SizedBox(height: 18),
                _buildStatsRow(context),
                const SizedBox(height: 14),
                _buildOnTimeBanner(context),
                const SizedBox(height: 22),
                _buildRecordsHeader(context),
                const SizedBox(height: 12),
                ..._records.map(
                      (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRecordCard(context, r),
                  ),
                ),
                const SizedBox(height: 8),
                _buildPunchAdjustmentCard(context),
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
            "Attendance History",
            fontSize: 18,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
        ),
        InkWell(
          onTap: () => _openCalendarPicker(context),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.calendar_month_rounded, color: AppColors.headlineTextColor),
          ),
        ),
        InkWell(
          onTap: () {
            // TODO: open advanced filter sheet (status, shift, etc.)
          },
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.tune_rounded, color: AppColors.headlineTextColor),
          ),
        ),
      ],
    );
  }

  // ==================== OVERVIEW HEADER ====================
  Widget _buildOverviewHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CaptionText("Monthly Overview & Logs"),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // TODO: open advanced filter sheet
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune_rounded, size: 14, color: AppColors.primaryColor),
                    const SizedBox(width: 6),
                    AppText(
                      "Filter",
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AppText(_monthLabel(_selectedMonth), fontSize: 24, fontWeight: FontWeight.w700),
      ],
    );
  }

  // ==================== MONTH SCROLLER ====================
  Widget _buildMonthScroller(BuildContext context) {
    final months = [
      DateTime(_selectedMonth.year, _selectedMonth.month - 2),
      DateTime(_selectedMonth.year, _selectedMonth.month - 1),
      _selectedMonth,
    ];

    return Row(
      children: [
        InkWell(
          onTap: () => _shiftMonth(-1),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.chevron_left_rounded, color: AppColors.labelTextColor),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: months.map((m) {
              final bool active = m.year == _selectedMonth.year && m.month == _selectedMonth.month;
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _selectedMonth = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (active) ...[
                        Container(
                          height: 6,
                          width: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.whiteColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      AppText(
                        _monthShortLabel(m),
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? AppColors.whiteColor : AppColors.labelTextColor,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        InkWell(
          onTap: () => _shiftMonth(1),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.chevron_right_rounded, color: AppColors.labelTextColor),
          ),
        ),
      ],
    );
  }

  // ==================== STATS ROW ====================
  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatPill(
            color: AppColors.successColor,
            value: "$_presentCount",
            label: "Present",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            color: AppColors.warningColor,
            value: "$_lateCount",
            label: "Late",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            color: AppColors.errorColor,
            value: "$_missingCount",
            label: "Missing",
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill({required Color color, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              AppText(value, fontSize: 20, fontWeight: FontWeight.w700),
            ],
          ),
          const SizedBox(height: 4),
          CaptionText(label),
        ],
      ),
    );
  }

  // ==================== ON-TIME BANNER ====================
  Widget _buildOnTimeBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.insights_rounded, color: AppColors.whiteColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  "$_onTimeRate On-Time Rate",
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 2),
                CaptionText(_onTimeDelta),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AppText(
              "Great job!",
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== RECORDS HEADER ====================
  Widget _buildRecordsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          "DAILY RECORDS",
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: AppColors.labelTextColor,
        ),
        CaptionText("Showing ${_records.length} entries"),
      ],
    );
  }

  // ==================== RECORD CARD ====================
  Widget _buildRecordCard(BuildContext context, _DailyRecord record) {
    final Color accent = _statusColor(record.status);

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
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.cardBgColor,
                borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildDateBox(record.date),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInOutColumn(record)),
                  const SizedBox(width: 8),
                  _buildDurationAndStatus(record, accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(DateTime date) {
    const weekdayShort = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fieldFillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          AppText("${date.day}", fontSize: 18, fontWeight: FontWeight.w800),
          const SizedBox(height: 2),
          AppText(
            weekdayShort[date.weekday - 1],
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.labelTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInOutColumn(_DailyRecord record) {
    final bool isLate = record.status == _AttendanceStatus.late;
    final bool isMissing = record.status == _AttendanceStatus.missingCheckout;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              isLate ? Icons.watch_later_rounded : Icons.login_rounded,
              size: 14,
              color: isLate ? AppColors.warningColor : AppColors.successColor,
            ),
            const SizedBox(width: 6),
            AppText(
              "In: ${record.inTime}",
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isLate ? AppColors.warningColor : AppColors.headlineTextColor,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              isMissing
                  ? Icons.warning_amber_rounded
                  : (record.outTime == null ? Icons.sync_rounded : Icons.logout_rounded),
              size: 14,
              color: isMissing
                  ? AppColors.errorColor
                  : (record.outTime == null ? AppColors.primaryColor : AppColors.errorColor),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: AppText(
                isMissing
                    ? "Out: --:--"
                    : "Out: ${record.outTime ?? "In Progress..."}",
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isMissing
                    ? AppColors.errorColor
                    : (record.outTime == null ? AppColors.primaryColor : AppColors.headlineTextColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationAndStatus(_DailyRecord record, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(record.workedLabel, fontSize: 15, fontWeight: FontWeight.w700),
        const SizedBox(height: 6),
        _buildStatusChip(record, accent),
      ],
    );
  }

  Widget _buildStatusChip(_DailyRecord record, Color color) {
    final String label = switch (record.status) {
      _AttendanceStatus.working => "Working",
      _AttendanceStatus.onTime => "On Time",
      _AttendanceStatus.late => "Late (${record.lateMinutes}m)",
      _AttendanceStatus.missingCheckout => "Missing Checkout",
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          record.status == _AttendanceStatus.working
              ? _BlinkingDot(color: color)
              : (record.status == _AttendanceStatus.missingCheckout
              ? Icon(Icons.error_rounded, size: 11, color: color)
              : Container(
            height: 6,
            width: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )),
          const SizedBox(width: 5),
          AppText(label, fontSize: 10, fontWeight: FontWeight.w700, color: color),
        ],
      ),
    );
  }

  Color _statusColor(_AttendanceStatus status) {
    switch (status) {
      case _AttendanceStatus.working:
        return AppColors.infoColor;
      case _AttendanceStatus.onTime:
        return AppColors.successColor;
      case _AttendanceStatus.late:
        return AppColors.warningColor;
      case _AttendanceStatus.missingCheckout:
        return AppColors.errorColor;
    }
  }

  // ==================== PUNCH ADJUSTMENT CARD ====================
  Widget _buildPunchAdjustmentCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
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
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_note_rounded, size: 18, color: AppColors.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText("Need a punch adjustment?", fontSize: 14, fontWeight: FontWeight.w700),
                    const SizedBox(height: 3),
                    AppText(
                      "Requests for missing punches on Oct 18 must be submitted by Monday.",
                      fontSize: 12,
                      color: AppColors.bodyTextColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    // TODO: Navigator.pushNamed(context, AppRoutes.punchClaim);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AppText(
                      "Submit Claim",
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    // TODO: export current month history (CSV/PDF)
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryColor.withOpacity(.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.file_download_outlined, size: 15, color: AppColors.primaryColor),
                        const SizedBox(width: 6),
                        AppText(
                          "Export",
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== CALENDAR PICKER (table_calendar) ====================
  Future<void> _openCalendarPicker(BuildContext context) async {
    DateTime tempFocused = _focusedCalendarDay;
    DateTime? tempSelected = _selectedCalendarDay;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText("Jump to date", fontSize: 16, fontWeight: FontWeight.w700),
                      InkWell(
                        onTap: () => Navigator.pop(sheetContext),
                        child: const Icon(Icons.close_rounded, color: AppColors.labelTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TableCalendar(
                    firstDay: DateTime(2020, 1, 1),
                    lastDay: DateTime.now(),
                    focusedDay: tempFocused,
                    selectedDayPredicate: (day) => isSameDay(tempSelected, day),
                    onDaySelected: (selected, focused) {
                      setSheetState(() {
                        tempSelected = selected;
                        tempFocused = focused;
                      });
                    },
                    onPageChanged: (focused) {
                      tempFocused = focused;
                    },
                    calendarFormat: CalendarFormat.month,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headlineTextColor,
                      ),
                      leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.labelTextColor),
                      rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.labelTextColor),
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
                      defaultTextStyle: const TextStyle(fontFamily: "Poppins", fontSize: 13),
                      weekendTextStyle: const TextStyle(fontFamily: "Poppins", fontSize: 13),
                      todayDecoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(.15),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: const TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w700,
                        color: AppColors.whiteColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() {
                          _focusedCalendarDay = tempFocused;
                          _selectedCalendarDay = tempSelected;
                          if (tempSelected != null) {
                            _selectedMonth = DateTime(tempSelected!.year, tempSelected!.month);
                          }
                        });
                        // TODO: refetch _records for _selectedMonth / _selectedCalendarDay
                        Navigator.pop(sheetContext);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: AppText(
                          "Apply",
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.whiteColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _monthLabel(DateTime date) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return "${months[date.month - 1]} ${date.year}";
  }

  String _monthShortLabel(DateTime date) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${months[date.month - 1]} ${date.year}";
  }
}

/// Live pulse dot for the "Working" status chip — mirrors the blinking
/// on-air indicator in the design. Runs on its own AnimationController
/// so it keeps blinking independently of list rebuilds.
class _BlinkingDot extends StatefulWidget {
  final Color color;
  const _BlinkingDot({required this.color});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1, end: .25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        height: 6,
        width: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _DailyRecord {
  final DateTime date;
  final String inTime;
  final String? outTime;
  final String workedLabel;
  final _AttendanceStatus status;
  final int lateMinutes;

  _DailyRecord({
    required this.date,
    required this.inTime,
    required this.outTime,
    required this.workedLabel,
    required this.status,
    this.lateMinutes = 0,
  });
}