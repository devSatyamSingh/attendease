import '../api/api_service.dart';
import '../api/api_urls.dart';
import '../core/errors/failure.dart';
import '../model/device_model.dart';
import '../model/login_response_model.dart';
import '../services/storage_service.dart';

/// AttendEase — auth repository.
/// ViewModels never call ApiService/StorageService directly — they go
/// through this repository, which is the only place that knows how a
/// login response maps onto local storage.
class AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthRepository({ApiService? apiService, StorageService? storageService})
      : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();

  /// [login] can be an employee code or a work email — the backend's
  /// `login` field accepts either. On success, saves tokens + session
  /// info and the device_id used, so the app never has to ask again.
  Future<LoginResponseModel> login({
    required String login,
    required String password,
    required DeviceModel device,
  }) async {
    final response = await _apiService.postApi(
      url: ApiUrls.login,
      body: {
        "login": login,
        "password": password,
        "device": device.toJson(),
      },
    );

    if (response is! Map<String, dynamic> || response['data'] == null) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }

    final loginResponse = LoginResponseModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );

    await _storageService.saveSession(loginResponse);
    await _storageService.saveDeviceId(device.deviceId);

    return loginResponse;
  }

  /// Logs the employee out locally. The API call is best-effort — the
  /// local session is cleared in `finally` regardless of whether the
  /// backend call succeeds, because that's what actually locks the app
  /// again (e.g. if there's no internet, the user should still be able
  /// to log out).
  Future<void> logout() async {
    try {
      await _apiService.postApi(url: ApiUrls.logout);
    } catch (_) {
      // Ignored on purpose — see doc comment above.
    } finally {
      await _storageService.clearSession();
    }
  }

  Future<bool> isLoggedIn() => _storageService.isLoggedIn();
}