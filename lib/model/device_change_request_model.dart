import '../utils/date_formatter.dart';

class DeviceChangeRequestModel {
  final int deviceChangeRequestId;
  final int employeeId;
  final int oldEmployeeDeviceId;
  final String newDeviceId;
  final String? newDeviceName;
  final String newDeviceModel;
  final String newPlatform;
  final String status; // "PENDING" / "APPROVED" / "REJECTED"
  final DateTime? requestedAt;
  final int? reviewedByAdminId;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  const DeviceChangeRequestModel({
    required this.deviceChangeRequestId,
    required this.employeeId,
    required this.oldEmployeeDeviceId,
    required this.newDeviceId,
    this.newDeviceName,
    required this.newDeviceModel,
    required this.newPlatform,
    required this.status,
    this.requestedAt,
    this.reviewedByAdminId,
    this.reviewedAt,
    this.rejectionReason,
  });

  factory DeviceChangeRequestModel.fromJson(Map<String, dynamic> json) {
    return DeviceChangeRequestModel(
      deviceChangeRequestId: json['device_change_request_id'] as int,
      employeeId: json['employee_id'] as int,
      oldEmployeeDeviceId: json['old_employee_device_id'] as int,
      newDeviceId: json['new_device_id'] as String,
      newDeviceName: json['new_device_name'] as String?,
      newDeviceModel: json['new_device_model'] as String,
      newPlatform: json['new_platform'] as String,
      status: json['status'] as String,
      requestedAt: DateFormatter.parseApiDateTime(json['requested_at'] as String?),
      reviewedByAdminId: json['reviewed_by_admin_id'] as int?,
      reviewedAt: DateFormatter.parseApiDateTime(json['reviewed_at'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}