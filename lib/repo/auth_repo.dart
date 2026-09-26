import '../api/api_service.dart';
import '../api/api_urls.dart';
import '../core/errors/failure.dart';
import '../model/device_model.dart';
import '../model/login_response_model.dart';
import '../services/storage_service.dart';

class AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthRepository({ApiService? apiService, StorageService? storageService})
      : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();


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

  Future<void> logout() async {
    try {
      await _apiService.postApi(url: ApiUrls.logout);
    } catch (_) {
    } finally {
      await _storageService.clearSession();
    }
  }

  Future<bool> isLoggedIn() => _storageService.isLoggedIn();
}