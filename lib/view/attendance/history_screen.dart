import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/errors/failure.dart';
import '../../model/attendance_model.dart';
import '../../viewmodel/attendance_viewmodel.dart';
import '../../widget/app_button.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';

enum _RowStatus { working, onTime, late, missingCheckout }

/// AttendEase — Attendance History screen.
/// Wired to [attendanceHistoryViewModelProvider]: changing the selected
/// month (chips, chevrons, or the calendar picker) reloads the list
/// scoped to that month's `from`/`to` range, and the stats row / on-time
/// rate are computed live from whatever's actually loaded for it.
class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends ConsumerState<AttendanceHistoryScreen> {
  late DateTime _selectedMonth;
  late DateTime _focusedCalendarDay;
  DateTime? _selectedCalendarDay;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _focusedCalendarDay = now;
    _selectedCalendarDay = now;

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(attendanceHistoryViewModelProvider.notifier).loadMore();
      }
    });

    // Load history scoped to the current month right away.
    Future.microtask(() => _loadMonth(_selectedMonth));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMonth(DateTime month) {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);
    ref.read(attendanceHistoryViewModelProvider.notifier).loadFirstPage(from: from, to: to);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    _loadMonth(_selectedMonth);
  }

  _RowStatus _statusFor(AttendanceModel r) {
    final today = DateTime.now();
    final recordDate = r.attendanceDate ?? r.createdAt;
    final isToday = recordDate != null &&
        recordDate.year == today.year &&
        recordDate.month == today.month &&
        recordDate.day == today.day;

    if (r.actualCheckOut == null) {
      return isToday ? _RowStatus.working : _RowStatus.missingCheckout;
    }
    if ((r.lateMinutes ?? 0) > 0) return _RowStatus.late;
    return _RowStatus.onTime;
  }

  Color _statusColor(_RowStatus status) {
    switch (status) {
      case _RowStatus.working:
        return AppColors.infoColor;
      case _RowStatus.onTime:
        return AppColors.successColor;
      case _RowStatus.late:
        return AppColors.warningColor;
      case _RowStatus.missingCheckout:
        return AppColors.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(attendanceHistoryViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () => ref.read(attendanceHistoryViewModelProvider.notifier).refresh(),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 18),
                  _buildOverviewHeader(context),
                  const SizedBox(height: 14),
                  _buildMonthScroller(context),
                  const SizedBox(height: 18),
                  if (historyState.isLoading)
                    const _HistorySkeleton()
                  else if (historyState.isEmpty && historyState.failure != null)
                    _buildErrorState(historyState.failure!)
                  else ...[
                      _buildStatsRow(historyState.items),
                      const SizedBox(height: 14),
                      _buildOnTimeBanner(historyState.items),
                      const SizedBox(height: 22),
                      _buildRecordsHeader(historyState.items.length),
                      const SizedBox(height: 12),
                      if (historyState.isEmpty)
                        _buildEmptyState()
                      else
                        ...historyState.items.map(
                              (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildRecordCard(context, r),
                          ),
                        ),
                      if (historyState.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                        ),
                    ],
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
            padding: EdgeInsets.all(6),
            child: Icon(Icons.arrow_back_rounded, color: AppColors.headlineTextColor),
          ),
        ),
        Expanded(
          child: AppText(
            "Attendance History",
            fontSize: 18,
            fontWeight: FontWeight.w500,
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
      ],
    );
  }

  // ==================== OVERVIEW HEADER ====================
  Widget _buildOverviewHeader(BuildContext context) {
    return AppText(_monthLabel(_selectedMonth), fontSize: 18, fontWeight: FontWeight.w600);
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
                onTap: () {
                  setState(() => _selectedMonth = m);
                  _loadMonth(m);
                },
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
                          decoration: const BoxDecoration(color: AppColors.whiteColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                      ],
                      AppText(
                        _monthShortLabel(m),
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
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

  // ==================== STATS ROW (computed from loaded month) ====================
  Widget _buildStatsRow(List<AttendanceModel> items) {
    final presentCount = items.where((r) => r.actualCheckIn != null).length;
    final lateCount = items.where((r) => (r.lateMinutes ?? 0) > 0).length;
    final missingCount = items.where((r) => _statusFor(r) == _RowStatus.missingCheckout).length;

    return Row(
      children: [
        Expanded(child: _buildStatPill(color: AppColors.successColor, value: "$presentCount", label: "Present")),
        const SizedBox(width: 10),
        Expanded(child: _buildStatPill(color: AppColors.warningColor, value: "$lateCount", label: "Late")),
        const SizedBox(width: 10),
        Expanded(child: _buildStatPill(color: AppColors.errorColor, value: "$missingCount", label: "Missing")),
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
              Container(height: 8, width: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              AppText(value, fontSize: 17, fontWeight: FontWeight.w600),
            ],
          ),
          const SizedBox(height: 4),
          CaptionText(label),
        ],
      ),
    );
  }

  // ==================== ON-TIME BANNER (computed from loaded month) ====================
  Widget _buildOnTimeBanner(List<AttendanceModel> items) {
    final completed = items.where((r) => r.actualCheckOut != null).toList();
    final onTimeCount = completed.where((r) => (r.lateMinutes ?? 0) == 0).length;
    final rate = completed.isEmpty ? 0.0 : (onTimeCount / completed.length) * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.insights_rounded, color: AppColors.whiteColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText("${rate.toStringAsFixed(1)}% On-Time Rate", fontSize: 12, fontWeight: FontWeight.w600),
                const SizedBox(height: 2),
                CaptionText(completed.isEmpty ? "No completed days yet this month" : "${completed.length} completed day${completed.length == 1 ? '' : 's'}"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== RECORDS HEADER ====================
  Widget _buildRecordsHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText("DAILY RECORDS", fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: AppColors.labelTextColor),
        CaptionText("Showing $count entries"),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.event_busy_rounded, size: 36, color: AppColors.placeholderColor),
          const SizedBox(height: 10),
          AppText("No attendance records for this month", fontSize: 13, color: AppColors.labelTextColor),
        ],
      ),
    );
  }

  Widget _buildErrorState(Failure failure) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.errorColor),
          const SizedBox(height: 10),
          AppText(failure.message, fontSize: 13, color: AppColors.labelTextColor, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          SizedBox(
            width: 140,
            child: AppButton(text: "Retry", icon: Icons.refresh_rounded, onTap: () => _loadMonth(_selectedMonth)),
          ),
        ],
      ),
    );
  }

  // ==================== RECORD CARD ====================
  Widget _buildRecordCard(BuildContext context, AttendanceModel record) {
    final status = _statusFor(record);
    final accent = _statusColor(status);
    final date = record.attendanceDate ?? record.createdAt ?? DateTime.now();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(color: accent, borderRadius: const BorderRadius.horizontal(left: Radius.circular(4))),
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
                  _buildDateBox(date),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInOutColumn(record, status)),
                  const SizedBox(width: 8),
                  _buildDurationAndStatus(record, status, accent),
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
      decoration: BoxDecoration(color: AppColors.fieldFillColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          AppText("${date.day}", fontSize: 18, fontWeight: FontWeight.w800),
          const SizedBox(height: 2),
          AppText(weekdayShort[date.weekday - 1], fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.labelTextColor),
        ],
      ),
    );
  }

  Widget _buildInOutColumn(AttendanceModel record, _RowStatus status) {
    final inLabel = record.actualCheckIn != null ? _formatTime(record.actualCheckIn!) : "--:--";
    final outLabel = record.actualCheckOut != null ? _formatTime(record.actualCheckOut!) : (status == _RowStatus.working ? "In Progress..." : "--:--");
    final bool isLate = status == _RowStatus.late;
    final bool isMissing = status == _RowStatus.missingCheckout;

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
              "In: $inLabel",
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
                  : (status == _RowStatus.working ? Icons.sync_rounded : Icons.logout_rounded),
              size: 14,
              color: isMissing ? AppColors.errorColor : (status == _RowStatus.working ? AppColors.primaryColor : AppColors.errorColor),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: AppText(
                isMissing ? "Out: --:--" : "Out: $outLabel",
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isMissing ? AppColors.errorColor : (status == _RowStatus.working ? AppColors.primaryColor : AppColors.headlineTextColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationAndStatus(AttendanceModel record, _RowStatus status, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(_workedLabel(record, status), fontSize: 13, fontWeight: FontWeight.w600),
        const SizedBox(height: 6),
        _buildStatusChip(record, status, accent),
      ],
    );
  }

  String _workedLabel(AttendanceModel record, _RowStatus status) {
    int? minutes = record.workedMinutes;
    if (minutes == null && status == _RowStatus.working && record.actualCheckIn != null) {
      minutes = DateTime.now().difference(record.actualCheckIn!.toLocal()).inMinutes;
    }
    if (minutes == null) return "--";
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return "${h}h ${m.toString().padLeft(2, '0')}m";
  }

  Widget _buildStatusChip(AttendanceModel record, _RowStatus status, Color color) {
    final String label = switch (status) {
      _RowStatus.working => "Working",
      _RowStatus.onTime => "On Time",
      _RowStatus.late => "Late (${record.lateMinutes}m)",
      _RowStatus.missingCheckout => "Missing Checkout",
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          status == _RowStatus.working
              ? _BlinkingDot(color: color)
              : (status == _RowStatus.missingCheckout
              ? Icon(Icons.error_rounded, size: 11, color: color)
              : Container(height: 6, width: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
          const SizedBox(width: 5),
          AppText(label, fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) => DateFormat("hh:mm a").format(dt.toLocal());

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
                    decoration: BoxDecoration(color: AppColors.borderColor, borderRadius: BorderRadius.circular(4)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText("Jump to date", fontSize: 14, fontWeight: FontWeight.w600),
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
                      titleTextStyle: TextStyle(fontFamily: "Poppins", fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.headlineTextColor),
                      leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.labelTextColor),
                      rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.labelTextColor),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontFamily: "Poppins", fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.labelTextColor),
                      weekendStyle: TextStyle(fontFamily: "Poppins", fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.labelTextColor),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      defaultTextStyle: const TextStyle(fontFamily: "Poppins", fontSize: 13),
                      weekendTextStyle: const TextStyle(fontFamily: "Poppins", fontSize: 13),
                      todayDecoration: BoxDecoration(color: AppColors.primaryColor.withOpacity(.15), shape: BoxShape.circle),
                      todayTextStyle: const TextStyle(fontFamily: "Poppins", fontWeight: FontWeight.w500, color: AppColors.primaryColor),
                      selectedDecoration: const BoxDecoration(color: AppColors.primaryColor, shape: BoxShape.circle),
                      selectedTextStyle: const TextStyle(fontFamily: "Poppins", fontWeight: FontWeight.w700, color: AppColors.whiteColor),
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
                        _loadMonth(_selectedMonth);
                        Navigator.pop(sheetContext);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(14)),
                        child: AppText("Apply", fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.whiteColor),
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
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${months[date.month - 1]} ${date.year}";
  }
}

/// Live pulse dot for the "Working" status chip.
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1, end: .25).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
      child: Container(height: 6, width: 6, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 84,
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