import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/storage_keys.dart';
import '../model/login_response_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }


  Future<void> saveAccessToken(String token) => _secureStorage.write(key: StorageKeys.accessToken, value: token);

  Future<String?> getAccessToken() => _secureStorage.read(key: StorageKeys.accessToken);

  Future<void> saveRefreshToken(String token) => _secureStorage.write(key: StorageKeys.refreshToken, value: token);

  Future<String?> getRefreshToken() => _secureStorage.read(key: StorageKeys.refreshToken);

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

  Future<void> updateDeviceStatus(String status) async {
    final prefs = await _preferences;
    await prefs.setString(StorageKeys.deviceStatus, status);
  }

  Future<void> saveDeviceId(String deviceId) async {
    final prefs = await _preferences;
    await prefs.setString(StorageKeys.deviceId, deviceId);
  }

  Future<String?> getDeviceId() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.deviceId);
  }

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
  }
}