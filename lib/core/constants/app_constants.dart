
class AppConstants {
  AppConstants._();

  // ---------------- APP INFO ----------------
  static const String appName = "AttendEase";
  static const String appTagline = "Smart Employee Attendance";
  static const String appVersion = "1.0.0";
  static const String supportEmail = "support@attendease.com";
  static const String supportPhone = "+91-9999999999";

  // ---------------- TIMEOUTS ----------------
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  // ---------------- SPLASH / ANIMATION ----------------
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration debounceDuration = Duration(milliseconds: 500);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);

  static const double gpsAccuracyThresholdMeters = 50.0;
  static const int defaultDailyGoalHours = 8;

  // ---------------- PAGINATION ----------------
  static const int defaultPageSize = 20;

  // ---------------- VALIDATION ----------------
  static const int minPasswordLength = 6;
  static const int maxLeaveReasonLength = 250;

  // ---------------- DATE / TIME FORMATS ----------------
  static const String dateFormat = "dd MMM yyyy";
  static const String timeFormat = "hh:mm a";
  static const String dateTimeFormat = "dd MMM yyyy, hh:mm a";
  static const String apiDateFormat = "yyyy-MM-dd";
  static const String businessTimezone = "Asia/Kolkata";

  // ---------------- HIVE BOX NAMES ----------------
  static const String attendanceHistoryBox = "attendance_history_box";
  static const String leaveHistoryBox = "leave_history_box";
  static const String userBox = "user_box";
}