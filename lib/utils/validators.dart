
class Validators {
  Validators._();

  static String? required(String? value, {String fieldName = "This field"}) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    return null;
  }

  static String? employeeIdOrEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Employee ID or email is required";
    }
    if (value.contains('@')) {
      return email(value);
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return "Enter a valid email address";
    }
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    if (value.length < minLength) {
      return "Password must be at least $minLength characters";
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Phone number is required";
    }
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return "Enter a valid 10-digit phone number";
    }
    return null;
  }

  static String? otp(String? value, {int length = 6}) {
    if (value == null || value.trim().isEmpty) {
      return "OTP is required";
    }
    if (value.trim().length != length) {
      return "Enter the $length-digit OTP";
    }
    return null;
  }

  static String? leaveReason(String? value, {int maxLength = 250}) {
    if (value != null && value.length > maxLength) {
      return "Reason must be under $maxLength characters";
    }
    return null;
  }

  static String? deviceChangeReason(String? value, {int maxLength = 250}) {
    if (value != null && value.length > maxLength) {
      return "Reason must be under $maxLength characters";
    }
    return null;
  }

  static String? dateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return "Please select both start and end dates";
    }
    if (end.isBefore(start)) {
      return "End date cannot be before start date";
    }
    return null;
  }
}