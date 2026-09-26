import 'active_device_model.dart';
import 'device_change_request_model.dart';

class DeviceStatusModel {
  final ActiveDeviceModel? activeDevice;
  final DeviceChangeRequestModel? pendingRequest;

  const DeviceStatusModel({this.activeDevice, this.pendingRequest});

  factory DeviceStatusModel.fromJson(Map<String, dynamic> json) {
    return DeviceStatusModel(
      activeDevice: json['active_device'] == null
          ? null
          : ActiveDeviceModel.fromJson(
        json['active_device'] as Map<String, dynamic>,
      ),
      pendingRequest: json['pending_request'] == null
          ? null
          : DeviceChangeRequestModel.fromJson(
        json['pending_request'] as Map<String, dynamic>,
      ),
    );
  }
}