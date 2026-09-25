/// AttendEase — parses the `data` array from
///   GET /holidays?from=YYYY-MM-DD&to=YYYY-MM-DD
class HolidayModel {
  final int holidayId;
  final DateTime holidayDate;
  final String name;
  final String holidayType; // "FULL_DAY" / "HALF_DAY"
  final String? halfDayPeriod; // "FIRST_HALF" / "SECOND_HALF" — null for FULL_DAY

  const HolidayModel({
    required this.holidayId,
    required this.holidayDate,
    required this.name,
    required this.holidayType,
    this.halfDayPeriod,
  });

  bool get isFullDay => holidayType.toUpperCase() == "FULL_DAY";

  /// True once the holiday's date has already passed (local calendar day).
  bool get isPast {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final holidayDateOnly = DateTime(holidayDate.year, holidayDate.month, holidayDate.day);
    return holidayDateOnly.isBefore(todayDateOnly);
  }

  bool get isToday {
    final today = DateTime.now();
    return holidayDate.year == today.year &&
        holidayDate.month == today.month &&
        holidayDate.day == today.day;
  }

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      holidayId: json['holiday_id'] as int,
      holidayDate: DateTime.parse(json['holiday_date'] as String),
      name: json['name'] as String,
      holidayType: json['holiday_type'] as String,
      halfDayPeriod: json['half_day_period'] as String?,
    );
  }
}