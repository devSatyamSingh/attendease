
class StorageKeys {
  StorageKeys._();

  // ---------------- SECURE STORAGE (sensitive — via flutter_secure_storage) ----------------
  static const String accessToken = "access_token";
  static const String refreshToken = "refresh_token";

  static const String isLoggedIn = "is_logged_in";
  static const String employeeId = "employee_id";
  static const String employeeCode = "employee_code";
  static const String employeeName = "employee_name";
  static const String employeeEmail = "employee_email";
  static const String employeeRole = "employee_role";
  static const String deviceId = "device_id";
  static const String deviceStatus = "device_status"; // ACTIVE / PENDING / REVOKED
  static const String selectedLanguage = "selected_language";
  static const String themeMode = "theme_mode";
  static const String onboardingSeen = "onboarding_seen";
  static const String lastSyncedAt = "last_synced_at";
  static const String fcmToken = "fcm_token";
  static const String biometricEnabled = "biometric_enabled";
}