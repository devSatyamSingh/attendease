/// AttendEase — centralized API endpoint paths.
/// Never hardcode a URL string inside a repository — always reference
/// ApiUrls.xxx. Only employee-facing endpoints are listed here; this
/// app never calls an /api/admin/* route.
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
  static const String attendanceToday = "/attendance/today";
  static const String checkIn = "/attendance/check-in";
  static const String checkOut = "/attendance/check-out";
  static const String attendanceHistory = "/attendance/history";
  static const String attendanceMonthlySummary = "/attendance/monthly-summary";
  static String attendanceDetail(int id) => "/attendance/$id";

  // ---------------- LEAVE ----------------
  static const String leaveTypes = "/leave/types";
  static const String leaveBalance = "/leave/balance";
  static const String leaveHistory = "/leave/history";
  static const String applyLeave = "/leave/requests";
  static String leaveRequestDetail(int id) => "/leave/requests/$id";
  static String cancelLeaveRequest(int id) => "/leave/requests/$id/cancel";

  // ---------------- PROFILE ----------------
  static const String profile = "/profile";
}