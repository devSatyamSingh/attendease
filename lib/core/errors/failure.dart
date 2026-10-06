
class Failure {
  final String message;
  final String? code;
  final int? statusCode;

  const Failure({required this.message, this.code, this.statusCode});

  @override
  String toString() => "Failure(code: $code, message: $message)";
}


class ServerFailure extends Failure {
  const ServerFailure({
    super.message = "Something went wrong on our server. Please try again.",
    super.code,
    super.statusCode,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = "No internet connection. Please check your network.",
    super.code,
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = "Request timed out. Please try again.",
    super.code,
  });
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code, super.statusCode});
}

class DeviceFailure extends Failure {
  const DeviceFailure({required super.message, super.code, super.statusCode});
}

class LocationFailure extends Failure {
  const LocationFailure({required super.message, super.code, super.statusCode});
}

class AttendanceFailure extends Failure {
  const AttendanceFailure({required super.message, super.code, super.statusCode});
}

class LeaveFailure extends Failure {
  const LeaveFailure({required super.message, super.code, super.statusCode});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code, super.statusCode});
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = "Could not read local data.",
    super.code,
  });
}

class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = "Something went wrong. Please try again.",
    super.code,
    super.statusCode,
  });
}
class FailureMapper {
  FailureMapper._();

  static Failure fromErrorCode(
      String? code, {
        String? fallbackMessage,
        int? statusCode,
      }) {
    // Backend ka message ho to wahi, warna default.
    String msg(String defaultMsg) =>
        (fallbackMessage != null && fallbackMessage.trim().isNotEmpty)
            ? fallbackMessage
            : defaultMsg;

    switch (code) {
    // ---------------- AUTH ----------------
      case 'INVALID_CREDENTIALS':
        return AuthFailure(
          message: msg("Incorrect ID or password. Please try again."),
          code: code,
          statusCode: statusCode,
        );
      case 'TOKEN_INVALID':
        return AuthFailure(
          message: msg("Your session has expired. Please log in again."),
          code: code,
          statusCode: statusCode,
        );
      case 'ACCOUNT_INACTIVE':
      case 'EMPLOYEE_INACTIVE':
        return AuthFailure(
          message: msg("Your account is inactive. Please contact admin."),
          code: code,
          statusCode: statusCode,
        );

    // ---------------- DEVICE ----------------
      case 'DEVICE_NOT_AUTHORIZED':
        return DeviceFailure(
          message: msg(
              "This device is not authorized. Please request a device change."),
          code: code,
          statusCode: statusCode,
        );
      case 'DEVICE_CHANGE_PENDING':
        return DeviceFailure(
          message:
          msg("Your device change request is awaiting admin approval."),
          code: code,
          statusCode: statusCode,
        );

    // ---------------- LOCATION ----------------
      case 'MOCK_LOCATION_DETECTED':
        return LocationFailure(
          message: msg("Fake location detected. Attendance not marked."),
          code: code,
          statusCode: statusCode,
        );
      case 'OUTSIDE_OFFICE':
      case 'OUTSIDE_AUTHORIZED_LOCATION':
        return LocationFailure(
          message: msg("You are outside your authorized attendance location."),
          code: code,
          statusCode: statusCode,
        );
      case 'GPS_PERMISSION_REQUIRED':
        return PermissionFailure(
          message: msg("Location permission is required to mark attendance."),
          code: code,
        );
      case 'GPS_ACCURACY_LOW':
        return LocationFailure(
          message: msg(
              "GPS accuracy is too low. Move to an open area and try again."),
          code: code,
          statusCode: statusCode,
        );
      case 'WFH_NOT_ENABLED':
        return LocationFailure(
          message: msg("Work-from-home attendance is not enabled for you."),
          code: code,
          statusCode: statusCode,
        );

    // ---------------- ATTENDANCE ----------------
      case 'ALREADY_CHECKED_IN':
        return AttendanceFailure(
          message: msg("You have already checked in today."),
          code: code,
          statusCode: statusCode,
        );
      case 'ALREADY_CHECKED_OUT':
        return AttendanceFailure(
          message: msg("You have already checked out today."),
          code: code,
          statusCode: statusCode,
        );
      case 'CHECKIN_REQUIRED':
        return AttendanceFailure(
          message: msg("Please check in before checking out."),
          code: code,
          statusCode: statusCode,
        );
      case 'ATTENDANCE_NOT_FOUND':
        return AttendanceFailure(
          message: msg("Attendance record not found."),
          code: code,
          statusCode: statusCode,
        );
      case 'WEEKEND':
        return AttendanceFailure(
          message: msg("Today is a weekend — attendance is not applicable."),
          code: code,
          statusCode: statusCode,
        );
      case 'FULL_DAY_HOLIDAY':
        return AttendanceFailure(
          message: msg("Today is a holiday — attendance is not applicable."),
          code: code,
          statusCode: statusCode,
        );
      case 'ON_APPROVED_LEAVE':
        return AttendanceFailure(
          message: msg("You are on approved leave today."),
          code: code,
          statusCode: statusCode,
        );

    // ---------------- LEAVE ----------------
      case 'LEAVE_TYPE_NOT_FOUND':
        return LeaveFailure(
          message: msg("Selected leave type is not available."),
          code: code,
          statusCode: statusCode,
        );
      case 'INSUFFICIENT_LEAVE_BALANCE':
        return LeaveFailure(
          message: msg("You don't have enough leave balance for this request."),
          code: code,
          statusCode: statusCode,
        );
      case 'LEAVE_OVERLAP':
        return LeaveFailure(
          message: msg("You already have a leave request on these dates."),
          code: code,
          statusCode: statusCode,
        );
      case 'INVALID_LEAVE_DATES':
        return LeaveFailure(
          message: msg("Please select a valid date range."),
          code: code,
          statusCode: statusCode,
        );
      case 'LEAVE_ALREADY_REVIEWED':
        return LeaveFailure(
          message: msg("This leave request has already been reviewed."),
          code: code,
          statusCode: statusCode,
        );
      case 'LEAVE_CANNOT_CANCEL':
        return LeaveFailure(
          message: msg("This leave request can no longer be cancelled."),
          code: code,
          statusCode: statusCode,
        );

    // ---------------- VALIDATION ----------------
      case 'VALIDATION_ERROR':
        return ValidationFailure(
          message: msg("Please check the details you entered."),
          code: code,
          statusCode: statusCode,
        );

      default:
        return ServerFailure(
          message: msg("Something went wrong. Please try again."),
          code: code,
          statusCode: statusCode,
        );
    }
  }
}