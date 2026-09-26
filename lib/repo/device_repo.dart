import '../api/api_service.dart';
import '../api/api_urls.dart';
import '../core/errors/failure.dart';
import '../model/device_change_request_model.dart';
import '../model/device_model.dart';
import '../model/device_status_model.dart';

class DeviceRepository {
  final ApiService _apiService;

  DeviceRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<DeviceStatusModel> getDeviceStatus() async {
    final response = await _apiService.getApi(url: ApiUrls.deviceStatus);

    if (response is! Map<String, dynamic> || response['data'] == null) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }
    return DeviceStatusModel.fromJson(response['data'] as Map<String, dynamic>);
  }


  Future<DeviceChangeRequestModel> requestDeviceChange(
      DeviceModel newDevice,
      ) async {
    final response = await _apiService.postApi(
      url: ApiUrls.deviceChangeRequest,
      body: {"device": newDevice.toJson()},
    );

    if (response is! Map<String, dynamic> || response['data'] == null) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }

    return DeviceChangeRequestModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }
}