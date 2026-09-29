
class ApiUrls {
  ApiUrls._();

  static const String baseUrl = "https://noida.fctesting.shop/api";

  // ---------------- AUTH ----------------
  static const String login = "/auth/login";
  static const String logout = "/auth/logout";
  static const String refreshToken = "/auth/refresh-token";
  static const String me = "/auth/me";

  // ---------------- DEVICE ----------------
  static const String registerDevice = "/devices/register";
  static const String deviceStatus = "/devices/status";
  static const String deviceChangeRequest = "/devices/change-request";

  // ---------------- ATTENDANCE ----------------
  static const String attendanceCheckIn = "/attendance/check-in";
  static const String attendanceCheckOut = "/attendance/check-out";
  static const String attendanceToday = "/attendance/today";
  static const String attendanceHistory = "/attendance/history";

  // ---------------- LEAVE ----------------
  static const String leaveTypes = "/leave/types";
  static const String leaveBalance = "/leave/balance";
  static const String leaveRequests = "/leave/requests";
  static const String leaveHistory = "/leave/history";

  // ---------------- HOLIDAY ----------------
  static const String holidays = "/holidays";
  static const String updateFcmToken = "/holidays";

  static const String fcmToken = "/notifications/fcm-token"; // POST + DELETE
  static const String notifications = "/notifications";
  static const String notificationUnreadCount = "/notifications/unread-count";
  static const String notificationReadAll = "/notifications/read-all";
  static String notificationRead(int id) => "/notifications/$id/read";


  // ---------------- PROFILE ----------------
  static const String profile = "/profile";
}