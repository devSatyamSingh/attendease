import '../utils/date_formatter.dart';


class AttendanceModel {
  final int attendanceId;
  final int employeeId;
  final DateTime? attendanceDate;
  final String status; // "CHECKED_IN" / "CHECKED_OUT" / "ABSENT" / ...
  final String expectedLoginTime; // "10:00:00"
  final String expectedLogoutTime; // "19:00:00"
  final DateTime? actualCheckIn;
  final DateTime? actualCheckOut;
  final bool isAutoCheckout;
  final int? lateMinutes;
  final int? earlyCheckoutMinutes;
  final int? workedMinutes;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkInAccuracy;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final double? checkOutAccuracy;
  final String? deviceId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttendanceModel({
    required this.attendanceId,
    required this.employeeId,
    this.attendanceDate,
    required this.status,
    required this.expectedLoginTime,
    required this.expectedLogoutTime,
    this.actualCheckIn,
    this.actualCheckOut,
    required this.isAutoCheckout,
    this.lateMinutes,
    this.earlyCheckoutMinutes,
    this.workedMinutes,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkInAccuracy,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkOutAccuracy,
    this.deviceId,
    this.createdAt,
    this.updatedAt,
  });

  /// True once checked in AND not yet checked out — the state the
  /// "Working" pulse chip on the History screen renders for.
  bool get isCurrentlyWorking => actualCheckIn != null && actualCheckOut == null;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      attendanceId: json['attendance_id'] as int,
      employeeId: json['employee_id'] as int,
      attendanceDate: DateFormatter.parseApiDateTime(json['attendance_date'] as String?),
      status: json['status'] as String,
      expectedLoginTime: json['expected_login_time'] as String,
      expectedLogoutTime: json['expected_logout_time'] as String,
      actualCheckIn: DateFormatter.parseApiDateTime(json['actual_check_in'] as String?),
      actualCheckOut: DateFormatter.parseApiDateTime(json['actual_check_out'] as String?),
      // Backend sends 0/1 (MySQL TINYINT), but guard against a future
      // switch to real booleans too.
      isAutoCheckout: json['is_auto_checkout'] == 1 || json['is_auto_checkout'] == true,
      lateMinutes: json['late_minutes'] as int?,
      earlyCheckoutMinutes: json['early_checkout_minutes'] as int?,
      workedMinutes: json['worked_minutes'] as int?,
      checkInLatitude: _parseDouble(json['check_in_latitude']),
      checkInLongitude: _parseDouble(json['check_in_longitude']),
      checkInAccuracy: _parseDouble(json['check_in_accuracy']),
      checkOutLatitude: _parseDouble(json['check_out_latitude']),
      checkOutLongitude: _parseDouble(json['check_out_longitude']),
      checkOutAccuracy: _parseDouble(json['check_out_accuracy']),
      deviceId: json['device_id'] as String?,
      createdAt: DateFormatter.parseApiDateTime(json['created_at'] as String?),
      updatedAt: DateFormatter.parseApiDateTime(json['updated_at'] as String?),
    );
  }
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

/// AttendEase — `pagination` block inside `GET /attendance/history`.
class AttendancePaginationModel {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const AttendancePaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory AttendancePaginationModel.fromJson(Map<String, dynamic> json) {
    return AttendancePaginationModel(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}

class AttendanceHistoryResponseModel {
  final List<AttendanceModel> items;
  final AttendancePaginationModel pagination;

  const AttendanceHistoryResponseModel({required this.items, required this.pagination});

  factory AttendanceHistoryResponseModel.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryResponseModel(
      items: (json['items'] as List)
          .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: AttendancePaginationModel.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}