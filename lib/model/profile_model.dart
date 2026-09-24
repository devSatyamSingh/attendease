import '../utils/date_formatter.dart';

/// AttendEase — parses `data` from `GET /profile`:
/// employee_id, employee_code, name, email, phone,
/// expected_login_time, expected_logout_time, late_grace_minutes,
/// status, created_at, updated_at.
class ProfileModel {
  final int employeeId;
  final String employeeCode;
  final String name;
  final String email;
  final String phone;
  final String expectedLoginTime; // "10:00:00" — display via DateFormatter as needed
  final String expectedLogoutTime; // "19:00:00"
  final int lateGraceMinutes;
  final String status; // "ACTIVE" / "INACTIVE"
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.employeeId,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.phone,
    required this.expectedLoginTime,
    required this.expectedLogoutTime,
    required this.lateGraceMinutes,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      employeeId: json['employee_id'] as int,
      employeeCode: json['employee_code'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      expectedLoginTime: json['expected_login_time'] as String,
      expectedLogoutTime: json['expected_logout_time'] as String,
      lateGraceMinutes: json['late_grace_minutes'] as int,
      status: json['status'] as String,
      createdAt: DateFormatter.parseApiDateTime(json['created_at'] as String?),
      updatedAt: DateFormatter.parseApiDateTime(json['updated_at'] as String?),
    );
  }
}