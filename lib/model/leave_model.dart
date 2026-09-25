import '../utils/date_formatter.dart';

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

/// AttendEase — `GET /leave/types` — `data` array item.
class LeaveTypeModel {
  final int leaveTypeId;
  final String name;
  final String code; // "CL" / "SL" / "EL/PL" / "LWP"
  final double defaultAnnualDays;

  const LeaveTypeModel({
    required this.leaveTypeId,
    required this.name,
    required this.code,
    required this.defaultAnnualDays,
  });

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeModel(
      leaveTypeId: json['leave_type_id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      defaultAnnualDays: _parseDouble(json['default_annual_days']) ?? 0,
    );
  }
}

/// AttendEase — `GET /leave/balance?year=` — `data` array item.
class LeaveBalanceModel {
  final int employeeLeaveBalanceId;
  final int employeeId;
  final int leaveTypeId;
  final int year;
  final double allocatedDays;
  final double usedDays;
  final double remainingDays;

  const LeaveBalanceModel({
    required this.employeeLeaveBalanceId,
    required this.employeeId,
    required this.leaveTypeId,
    required this.year,
    required this.allocatedDays,
    required this.usedDays,
    required this.remainingDays,
  });

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceModel(
      employeeLeaveBalanceId: json['employee_leave_balance_id'] as int,
      employeeId: json['employee_id'] as int,
      leaveTypeId: json['leave_type_id'] as int,
      year: json['year'] as int,
      allocatedDays: _parseDouble(json['allocated_days']) ?? 0,
      usedDays: _parseDouble(json['used_days']) ?? 0,
      remainingDays: _parseDouble(json['remaining_days']) ?? 0,
    );
  }
}

/// AttendEase — one leave request. Same shape returned by:
///   POST /leave/requests            (the applied request)
///   GET  /leave/history             (one per item in `items`)
///   GET  /leave/requests/{id}
class LeaveRequestModel {
  final int leaveRequestId;
  final int employeeId;
  final int leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final String leaveDurationType; // FULL_DAY / FIRST_HALF / SECOND_HALF
  final double totalDays;
  final String? reason;
  final String status; // PENDING / APPROVED / REJECTED / CANCELLED
  final DateTime? appliedAt;
  final int? reviewedByAdminId;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LeaveRequestModel({
    required this.leaveRequestId,
    required this.employeeId,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.leaveDurationType,
    required this.totalDays,
    this.reason,
    required this.status,
    this.appliedAt,
    this.reviewedByAdminId,
    this.reviewedAt,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status.toUpperCase() == "PENDING";
  bool get isApproved => status.toUpperCase() == "APPROVED";
  bool get isRejected => status.toUpperCase() == "REJECTED";
  bool get isCancelled => status.toUpperCase() == "CANCELLED";
  bool get isSingleDay =>
      startDate.year == endDate.year && startDate.month == endDate.month && startDate.day == endDate.day;

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      leaveRequestId: json['leave_request_id'] as int,
      employeeId: json['employee_id'] as int,
      leaveTypeId: json['leave_type_id'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      leaveDurationType: json['leave_duration_type'] as String,
      totalDays: _parseDouble(json['total_days']) ?? 0,
      reason: json['reason'] as String?,
      status: json['status'] as String,
      appliedAt: DateFormatter.parseApiDateTime(json['applied_at'] as String?),
      reviewedByAdminId: json['reviewed_by_admin_id'] as int?,
      reviewedAt: DateFormatter.parseApiDateTime(json['reviewed_at'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateFormatter.parseApiDateTime(json['created_at'] as String?),
      updatedAt: DateFormatter.parseApiDateTime(json['updated_at'] as String?),
    );
  }
}

/// `pagination` block inside `GET /leave/history`.
class LeavePaginationModel {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const LeavePaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory LeavePaginationModel.fromJson(Map<String, dynamic> json) {
    return LeavePaginationModel(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}

/// Full `data` block of `GET /leave/history`: `{ items, pagination }`.
class LeaveHistoryResponseModel {
  final List<LeaveRequestModel> items;
  final LeavePaginationModel pagination;

  const LeaveHistoryResponseModel({required this.items, required this.pagination});

  factory LeaveHistoryResponseModel.fromJson(Map<String, dynamic> json) {
    return LeaveHistoryResponseModel(
      items: (json['items'] as List)
          .map((e) => LeaveRequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: LeavePaginationModel.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}