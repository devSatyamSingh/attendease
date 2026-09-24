/// AttendEase — device payload sent to the backend on login and on a
/// device-change request. Matches the exact `device` object shape from
/// the API spec:
/// { "device_id", "model", "platform", "os_version", "app_version" }
class DeviceModel {
  final String deviceId;
  final String model;
  final String platform; // "ANDROID" / "IOS"
  final String osVersion;
  final String appVersion;

  const DeviceModel({
    required this.deviceId,
    required this.model,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() => {
    "device_id": deviceId,
    "model": model,
    "platform": platform,
    "os_version": osVersion,
    "app_version": appVersion,
  };
}