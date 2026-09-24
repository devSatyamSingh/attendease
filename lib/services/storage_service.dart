import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/storage_keys.dart';
import '../model/login_response_model.dart';

/// AttendEase — single source of truth for everything persisted on the
/// device: tokens (secure), and session/device info (SharedPreferences).
///
/// Never call `FlutterSecureStorage()` or `SharedPreferences` directly
/// anywhere else in the app — always go through `StorageService()`.
/// This is what the Splash screen reads to decide Login vs Dashboard,
/// what ApiClient reads to attach the Authorization header, and what
/// gets wiped on logout.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Plain default constructor — works across flutter_secure_storage
  // versions. If your resolved version supports it, you can opt back
  // into encrypted SharedPreferences on Android with:
  //   const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true))
  // Run `flutter pub deps flutter_secure_storage` to check your
  // resolved version first.
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==================== TOKENS (secure storage) ====================

  Future<void> saveAccessToken(String token) =>
      _secureStorage.write(key: StorageKeys.accessToken, value: token);

  Future<String?> getAccessToken() =>
      _secureStorage.read(key: StorageKeys.accessToken);

  Future<void> saveRefreshToken(String token) =>
      _secureStorage.write(key: StorageKeys.refreshToken, value: token);

  Future<String?> getRefreshToken() =>
      _secureStorage.read(key: StorageKeys.refreshToken);

  // ==================== FULL LOGIN SESSION ====================

  /// Call this right after a successful login response — saves
  /// everything the Splash screen and the rest of the app need to know
  /// "who is logged in" without ever calling the API again just to
  /// check that.
  Future<void> saveSession(LoginResponseModel loginResponse) async {
    final prefs = await _preferences;
    await Future.wait([
      saveAccessToken(loginResponse.accessToken),
      saveRefreshToken(loginResponse.refreshToken),
      prefs.setBool(StorageKeys.isLoggedIn, true),
      prefs.setInt(StorageKeys.employeeId, loginResponse.user.id),
      prefs.setString(StorageKeys.employeeName, loginResponse.user.name),
      prefs.setString(StorageKeys.employeeRole, loginResponse.user.role),
      prefs.setString(StorageKeys.deviceStatus, loginResponse.deviceStatus),
    ]);
  }

  /// Splash screen calls this to decide which screen to open first.
  Future<bool> isLoggedIn() async {
    final prefs = await _preferences;
    return prefs.getBool(StorageKeys.isLoggedIn) ?? false;
  }

  Future<int?> getEmployeeId() async {
    final prefs = await _preferences;
    return prefs.getInt(StorageKeys.employeeId);
  }

  Future<String?> getEmployeeName() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.employeeName);
  }

  Future<String?> getEmployeeRole() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.employeeRole);
  }

  Future<String?> getDeviceStatus() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.deviceStatus);
  }

  /// Call after a device-change-request response, or after a fresh
  /// login on a newly-approved device — keeps the locally cached
  /// device_status in sync with the backend without a full re-login.
  Future<void> updateDeviceStatus(String status) async {
    final prefs = await _preferences;
    await prefs.setString(StorageKeys.deviceStatus, status);
  }

  // ==================== DEVICE ====================

  /// The physical device's own identifier — generated once by
  /// DeviceInfoService and reused on every login/attendance call, so
  /// save it here the first time it's generated.
  Future<void> saveDeviceId(String deviceId) async {
    final prefs = await _preferences;
    await prefs.setString(StorageKeys.deviceId, deviceId);
  }

  Future<String?> getDeviceId() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.deviceId);
  }

  // ==================== LOGOUT ====================

  /// Clears everything a logged-in session touched. Call this both on
  /// a normal logout AND when a refresh-token call fails (forced
  /// logout) — see ApiClient's 401 handling.
  Future<void> clearSession() async {
    final prefs = await _preferences;
    await Future.wait([
      _secureStorage.delete(key: StorageKeys.accessToken),
      _secureStorage.delete(key: StorageKeys.refreshToken),
      prefs.remove(StorageKeys.isLoggedIn),
      prefs.remove(StorageKeys.employeeId),
      prefs.remove(StorageKeys.employeeName),
      prefs.remove(StorageKeys.employeeRole),
      prefs.remove(StorageKeys.deviceStatus),
    ]);
    // Note: deviceId is deliberately NOT cleared here — the physical
    // device doesn't change just because the employee logged out, and
    // the backend still recognizes this same device_id on next login.
  }
}