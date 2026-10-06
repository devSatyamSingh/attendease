import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:table_calendar/table_calendar.dart';
import '../../core/errors/failure.dart';
import '../../localization/lanaguge_provider.dart';
import '../../model/attendance_model.dart';
import '../../utils/app_topbar.dart';
import '../../viewmodel/attendance_viewmodel.dart';
import '../../widget/app_button.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';
import 'attendance_status.dart';

// ==================== HELPERS ====================
/// Time / number ka order Urdu me ulta na ho.
String _ltrIso(String s) => '\u2066$s\u2069';

/// TextStyle wale raw widgets (calendar) ke liye font.
String _fontFor(BuildContext c) =>
    Localizations.localeOf(c).languageCode == 'ur' ? 'NotoNastaliqUrdu' : 'Poppins';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends ConsumerState<AttendanceHistoryScreen> {
  late DateTime _selectedMonth;
  late DateTime _focusedCalendarDay;
  DateTime? _selectedCalendarDay;
  DateTime? _filteredDay;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _focusedCalendarDay = now;
    _selectedCalendarDay = now;

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(attendanceHistoryViewModelProvider.notifier).loadMore();
      }
    });

    // Current month ki history turant load karo.
    Future.microtask(() => _loadMonth(_selectedMonth));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMonth(DateTime month) {
    _filteredDay = null;
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);
    ref.read(attendanceHistoryViewModelProvider.notifier).loadFirstPage(from: from, to: to);
  }

  void _loadDay(DateTime day) {
    setState(() => _filteredDay = day);
    final dayOnly = DateTime(day.year, day.month, day.day);
    ref
        .read(attendanceHistoryViewModelProvider.notifier)
        .loadFirstPage(from: dayOnly, to: dayOnly);
  }

  void _clearDayFilter() {
    _loadMonth(_selectedMonth);
    setState(() {});
  }

  void _shiftMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    _loadMonth(_selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    // Language badalte hi ye tab turant rebuild ho
    ref.watch(languageProvider);

    final historyState = ref.watch(attendanceHistoryViewModelProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final hPad = (screenWidth * 0.045).clamp(12.0, 24.0);
    final maxContentWidth = screenWidth > 700 ? 520.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () =>
                  ref.read(attendanceHistoryViewModelProvider.notifier).refresh(),
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsetsDirectional.fromSTEB(hPad, 6, hPad, 16),
                children: [
                  AppTopBar(
                    title: 'attendance_history.title'.tr(),
                    trailing: AppTopBarAction(
                      icon: Icons.calendar_month_rounded,
                      onTap: () => _openCalendarPicker(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildOverviewHeader(context),
                  const SizedBox(height: 10),
                  _buildMonthScroller(context),
                  const SizedBox(height: 14),
                  if (historyState.isLoading)
                    const _HistorySkeleton()
                  else if (historyState.isEmpty && historyState.failure != null)
                    _buildErrorState(historyState.failure!)
                  else ...[
                      _buildStatsRow(historyState.items),
                      const SizedBox(height: 12),
                      _buildOnTimeBanner(historyState.items),
                      const SizedBox(height: 18),
                      _buildRecordsHeader(historyState.items.length),
                      const SizedBox(height: 10),
                      if (historyState.isEmpty)
                        _buildEmptyState()
                      else
                        ...historyState.items.map(
                              (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildRecordCard(context, r),
                          ),
                        ),
                      if (historyState.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2.2)),
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

  // ==================== OVERVIEW HEADER ====================
  Widget _buildOverviewHeader(BuildContext context) {
    return AppText(
      _monthLabel(_selectedMonth),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
  }

  // ==================== MONTH SCROLLER ====================
  Widget _buildMonthScroller(BuildContext context) {
    final months = [
      DateTime(_selectedMonth.year, _selectedMonth.month - 2),
      DateTime(_selectedMonth.year, _selectedMonth.month - 1),
      _selectedMonth,
    ];

    // Timeline hamesha purana -> naya (left to right), Urdu me bhi.
    // Isliye poora scroller LTR me lock hai, aur prev/next arrows sahi side pe rehte hain.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          InkWell(
            onTap: () => _shiftMonth(-1),
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.labelTextColor),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: months.map((m) {
                final bool active =
                    m.year == _selectedMonth.year && m.month == _selectedMonth.month;
                return Flexible(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() => _selectedMonth = m);
                      _loadMonth(m);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (active) ...[
                            Container(
                              height: 5,
                              width: 5,
                              decoration: const BoxDecoration(
                                color: AppColors.whiteColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Flexible(
                            child: AppText(
                              _monthShortLabel(m),
                              fontSize: 11,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                              color: active ? AppColors.whiteColor : AppColors.labelTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
              padding: EdgeInsets.all(4),
              child: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.labelTextColor),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STATS ROW ====================
  Widget _buildStatsRow(List<AttendanceModel> items) {
    final presentCount = items.where((r) => r.actualCheckIn != null).length;
    final lateCount =
        items.where((r) => r.displayStatus == AttendanceDisplayStatus.late).length;
    final missingCount = items
        .where((r) => r.displayStatus == AttendanceDisplayStatus.missingCheckout)
        .length;
    final leaveCount = items
        .where((r) =>
    r.displayStatus == AttendanceDisplayStatus.onLeave ||
        r.displayStatus == AttendanceDisplayStatus.halfDayLeave)
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatPill(
            color: AppColors.successColor,
            value: "$presentCount",
            label: 'attendance_history.present'.tr(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatPill(
            color: AppColors.warningColor,
            value: "$lateCount",
            label: 'attendance_history.late'.tr(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatPill(
            color: AppColors.errorColor,
            value: "$missingCount",
            label: 'attendance_history.missing'.tr(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatPill(
            color: AppColors.primaryColor,
            value: "$leaveCount",
            label: 'attendance_history.leave'.tr(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill({
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 7,
                width: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              AppText(value, fontSize: 15, fontWeight: FontWeight.w600),
            ],
          ),
          const SizedBox(height: 3),
          CaptionText(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== ON-TIME BANNER ====================
  Widget _buildOnTimeBanner(List<AttendanceModel> items) {
    final completed = items
        .where((r) =>
    r.displayStatus == AttendanceDisplayStatus.onTime ||
        r.displayStatus == AttendanceDisplayStatus.late)
        .toList();
    final onTimeCount = completed.where((r) => (r.lateMinutes ?? 0) == 0).length;
    final rate = completed.isEmpty ? 0.0 : (onTimeCount / completed.length) * 100;

    final completedLabel = completed.length == 1
        ? 'attendance_history.completed_one'.tr(args: ['${completed.length}'])
        : 'attendance_history.completed_many'.tr(args: ['${completed.length}']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.insights_rounded, color: AppColors.whiteColor, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'attendance_history.on_time_rate'.tr(args: [rate.toStringAsFixed(1)]),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 2),
                CaptionText(
                  completed.isEmpty
                      ? 'attendance_history.no_completed'.tr()
                      : completedLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== RECORDS HEADER ====================
  Widget _buildRecordsHeader(int count) {
    final locale = context.locale.toString();
    final entryLabel = count == 1
        ? 'attendance_history.entry_one'.tr(args: ['$count'])
        : 'attendance_history.entry_many'.tr(args: ['$count']);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: AppText(
                  'attendance_history.daily_records'.tr(),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .8,
                  color: AppColors.labelTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_filteredDay != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _clearDayFilter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close_rounded, size: 12, color: AppColors.primaryColor),
                        const SizedBox(width: 3),
                        AppText(
                          'attendance_history.clear'.tr(),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        CaptionText(
          _filteredDay != null
              ? "${DateFormat("d MMM", locale).format(_filteredDay!)} • $entryLabel"
              : 'attendance_history.showing'.tr(args: ['$count']),
        ),
      ],
    );
  }

  // ==================== EMPTY / ERROR ====================
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.event_busy_rounded, size: 32, color: AppColors.placeholderColor),
          const SizedBox(height: 8),
          AppText(
            _filteredDay != null
                ? 'attendance_history.empty_day'.tr()
                : 'attendance_history.empty_month'.tr(),
            fontSize: 12,
            color: AppColors.labelTextColor,
            textAlign: TextAlign.center,
          ),
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
          const SizedBox(height: 12),
          SizedBox(
            width: 130,
            child: AppButton(
              text: 'common.retry'.tr(),
              icon: Icons.refresh_rounded,
              height: 40,
              onTap: () => _loadMonth(_selectedMonth),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== RECORD CARD ====================
  Widget _buildRecordCard(BuildContext context, AttendanceModel record) {
    final status = record.displayStatus;
    final accent = record.statusColor;
    final date = (record.attendanceDate ?? record.createdAt ?? DateTime.now()).toLocal();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Color bar: LTR me left, RTL me right
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadiusDirectional.horizontal(
                start: Radius.circular(4),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.cardBgColor,
                borderRadius: BorderRadiusDirectional.horizontal(
                  end: Radius.circular(16),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildDateBox(context, date),
                  const SizedBox(width: 11),
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

  Widget _buildDateBox(BuildContext context, DateTime date) {
    // Hardcoded MON/TUE list hata di: ab selected language me aayega
    final weekday = DateFormat("EEE", context.locale.toString()).format(date).toUpperCase();
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.fieldFillColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          AppText("${date.day}", fontSize: 15, fontWeight: FontWeight.w700),
          const SizedBox(height: 1),
          AppText(
            weekday,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.labelTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInOutColumn(AttendanceModel record, AttendanceDisplayStatus status) {
    // Check-in hi nahi hua (leave / holiday / absent / not checked in)
    if (record.actualCheckIn == null) {
      return Row(
        children: [
          Icon(record.statusIcon, size: 13, color: record.statusColor),
          const SizedBox(width: 5),
          Flexible(
            child: AppText(
              record.statusSubtitle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: record.statusColor,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final bool isLate = status == AttendanceDisplayStatus.late;
    final bool isMissing = status == AttendanceDisplayStatus.missingCheckout;
    final bool isWorking = status == AttendanceDisplayStatus.working;

    final inLabel = _formatTime(record.actualCheckIn!);
    final outLabel = record.actualCheckOut != null
        ? _formatTime(record.actualCheckOut!)
        : (isWorking ? 'attendance_history.working_dots'.tr() : _ltrIso('--:--'));

    final Color outColor = isMissing
        ? AppColors.errorColor
        : (isWorking ? AppColors.primaryColor : AppColors.headlineTextColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              isLate ? Icons.watch_later_rounded : Icons.login_rounded,
              size: 13,
              color: isLate ? AppColors.warningColor : AppColors.successColor,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: AppText(
                'attendance_history.in_time'.tr(args: [inLabel]),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isLate ? AppColors.warningColor : AppColors.headlineTextColor,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(
              isMissing
                  ? Icons.warning_amber_rounded
                  : (isWorking ? Icons.sync_rounded : Icons.logout_rounded),
              size: 13,
              color: isMissing
                  ? AppColors.errorColor
                  : (isWorking ? AppColors.primaryColor : AppColors.errorColor),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: AppText(
                'attendance_history.out_time'.tr(args: [outLabel]),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: outColor,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationAndStatus(
      AttendanceModel record,
      AttendanceDisplayStatus status,
      Color accent,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (record.workedMinutes != null || status == AttendanceDisplayStatus.working) ...[
          AppText(
            _workedLabel(record, status),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 5),
        ],
        _buildStatusChip(record, status, accent),
      ],
    );
  }

  String _workedLabel(AttendanceModel record, AttendanceDisplayStatus status) {
    int? minutes = record.workedMinutes;
    if (minutes == null &&
        status == AttendanceDisplayStatus.working &&
        record.actualCheckIn != null) {
      minutes = DateTime.now().difference(record.actualCheckIn!.toLocal()).inMinutes;
    }
    if (minutes == null) return "--";
    final h = minutes ~/ 60;
    final m = minutes % 60;
    // Dashboard wali hi 'duration' key: "{}h {}m"
    return 'dashboard.duration'.tr(args: ['$h', m.toString().padLeft(2, '0')]);
  }

  Widget _buildStatusChip(
      AttendanceModel record,
      AttendanceDisplayStatus status,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          status == AttendanceDisplayStatus.working
              ? _BlinkingDot(color: color)
              : Icon(record.statusIcon, size: 10, color: color),
          const SizedBox(width: 4),
          AppText(
            record.statusLabel,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }

  /// "10:30 AM" (dashboard jaisa fixed AM/PM, LTR locked)
  String _formatTime(DateTime dt) =>
      _ltrIso(DateFormat("hh:mm a", 'en').format(dt.toLocal()));

  // ==================== CALENDAR PICKER (table_calendar) ====================
  Future<void> _openCalendarPicker(BuildContext context) async {
    DateTime tempFocused = _focusedCalendarDay;
    DateTime? tempSelected = _selectedCalendarDay;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final font = _fontFor(sheetContext);
        final isUrdu = font == 'NotoNastaliqUrdu';
        final locale = sheetContext.locale.toString();

        TextStyle style({
          double size = 12,
          Color color = AppColors.headlineTextColor,
        }) =>
            TextStyle(
              fontFamily: font,
              fontSize: size,
              fontWeight: FontWeight.w600,
              color: color,
              height: isUrdu ? 1.5 : null,
            );

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                16 + MediaQuery.of(sheetContext).padding.bottom,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        'attendance_history.jump_to_date'.tr(),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(sheetContext),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.labelTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Calendar grid LTR me lock (Mon..Sun order aur arrows sahi rahein),
                  // mahine/weekday ke naam locale se translate hote hain.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TableCalendar(
                      locale: locale,
                      firstDay: DateTime(2020, 1, 1),
                      lastDay: DateTime.now(),
                      focusedDay: tempFocused,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      availableGestures: AvailableGestures.horizontalSwipe,
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
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: style(size: 13),
                        leftChevronIcon: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.primaryColor,
                        ),
                        rightChevronIcon: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.primaryColor,
                        ),
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
                        disabledTextStyle:
                        style(color: AppColors.placeholderColor.withOpacity(.5)),
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
                    text: 'attendance_history.apply'.tr(),
                    icon: Icons.check_rounded,
                    gradient: AppColors.primaryGradient,
                    onTap: () {
                      setState(() {
                        _focusedCalendarDay = tempFocused;
                        _selectedCalendarDay = tempSelected;
                        if (tempSelected != null) {
                          _selectedMonth = DateTime(
                            tempSelected!.year,
                            tempSelected!.month,
                          );
                        }
                      });
                      if (tempSelected != null) {
                        _loadDay(tempSelected!);
                      } else {
                        _loadMonth(_selectedMonth);
                      }
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Hardcoded month lists hata di: ab DateFormat se locale ke hisaab se aate hain
  String _monthLabel(DateTime date) =>
      DateFormat("MMMM yyyy", context.locale.toString()).format(date);

  String _monthShortLabel(DateTime date) =>
      DateFormat("MMM yyyy", context.locale.toString()).format(date);
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1, end: .25)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 76,
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