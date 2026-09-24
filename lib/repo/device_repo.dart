import '../api/api_service.dart';
import '../api/api_urls.dart';
import '../core/errors/failure.dart';
import '../model/device_change_request_model.dart';
import '../model/device_model.dart';
import '../model/device_status_model.dart';

/// AttendEase — device repository.
class DeviceRepository {
  final ApiService _apiService;

  DeviceRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Used on the Login screen's device-warning banner and on the
  /// Device Change Request screen — tells you the currently active
  /// device AND whether a change request is already pending.
  Future<DeviceStatusModel> getDeviceStatus() async {
    final response = await _apiService.getApi(url: ApiUrls.deviceStatus);

    if (response is! Map<String, dynamic> || response['data'] == null) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }

    return DeviceStatusModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Submits a request to switch the active device — stays PENDING
  /// until an admin approves/rejects it (see DeviceChangeRequestModel).
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