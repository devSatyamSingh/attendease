import '../utils/date_formatter.dart';

/// AttendEase — the `active_device` object inside
/// `GET /devices/status`'s data block.
class ActiveDeviceModel {
  final int employeeDeviceId;
  final int employeeId;
  final String deviceId;
  final String? deviceName;
  final String deviceModel;
  final String platform;
  final String status; // "ACTIVE" / "REVOKED"
  final DateTime? registeredAt;
  final DateTime? lastLoginAt;

  const ActiveDeviceModel({
    required this.employeeDeviceId,
    required this.employeeId,
    required this.deviceId,
    this.deviceName,
    required this.deviceModel,
    required this.platform,
    required this.status,
    this.registeredAt,
    this.lastLoginAt,
  });

  factory ActiveDeviceModel.fromJson(Map<String, dynamic> json) {
    return ActiveDeviceModel(
      employeeDeviceId: json['employee_device_id'] as int,
      employeeId: json['employee_id'] as int,
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String?,
      deviceModel: json['device_model'] as String,
      platform: json['platform'] as String,
      status: json['status'] as String,
      registeredAt: DateFormatter.parseApiDateTime(json['registered_at'] as String?),
      lastLoginAt: DateFormatter.parseApiDateTime(json['last_login_at'] as String?),
    );
  }
}