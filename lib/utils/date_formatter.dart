import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFmt = DateFormat("dd MMM yyyy");
  static final DateFormat _timeFmt = DateFormat("hh:mm a");
  static final DateFormat _dateTimeFmt = DateFormat("dd MMM yyyy, hh:mm a");
  static final DateFormat _dayLabelFmt = DateFormat("EEEE, dd MMM yyyy");
  static final DateFormat _monthYearFmt = DateFormat("MMMM yyyy");
  static final DateFormat _apiDateFmt = DateFormat("yyyy-MM-dd");
  static final DateFormat _weekdayShortFmt = DateFormat("EEEE, dd MMM");


  static String formatDate(DateTime date) => _dateFmt.format(date);

  /// "10:08 AM"
  static String formatTime(DateTime date) => _timeFmt.format(date);

  /// "24 Sep 2026, 10:08 AM"
  static String formatDateTime(DateTime date) => _dateTimeFmt.format(date);

  /// "Thursday, 24 Sep 2026" — used on the Dashboard greeting subtitle.
  static String formatDayLabel(DateTime date) => _dayLabelFmt.format(date);

  /// "September 2026" — used on the Monthly Report month selector.
  static String formatMonthYear(DateTime date) => _monthYearFmt.format(date);

  /// "2026-09-24" — the format the backend expects in query params
  /// (e.g. GET /api/attendance/monthly?month=2026-09-24).
  static String toApiDate(DateTime date) => _apiDateFmt.format(date);

  static DateTime? parseApiDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String relativeDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    return _weekdayShortFmt.format(date);
  }

  static String formatMinutesToHm(int totalMinutes) {
    if (totalMinutes <= 0) return "0m";
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return "${minutes}m";
    if (minutes == 0) return "${hours}h";
    return "${hours}h ${minutes}m";
  }

  static String liveWorkedDuration(DateTime checkInTime) {
    final diff = DateTime.now().difference(checkInTime);
    return formatMinutesToHm(diff.inMinutes);
  }

  static DateTime firstDayOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime lastDayOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0);

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }
}