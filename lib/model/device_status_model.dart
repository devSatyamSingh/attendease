import 'active_device_model.dart';
import 'device_change_request_model.dart';

/// AttendEase — parses `data` from `GET /devices/status`:
/// { "active_device": {...} | null, "pending_request": {...} | null }
///
/// Login screen's device-warning banner and the Device Change Request
/// screen both read this: `pendingRequest != null` means a request is
/// already awaiting admin approval, so the UI shouldn't let the
/// employee submit a second one.
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