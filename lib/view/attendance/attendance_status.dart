import 'package:flutter/material.dart';
import '../../model/attendance_model.dart';
import '../../widget/app_colors.dart';


extension AttendanceStatusUi on AttendanceModel {
  String get statusLabel {
    switch (displayStatus) {
      case AttendanceDisplayStatus.working:
        return "Working";
      case AttendanceDisplayStatus.missingCheckout:
        return "Missing Checkout";
      case AttendanceDisplayStatus.late:
        return "Late (${lateMinutes}m)";
      case AttendanceDisplayStatus.onTime:
        return "On Time";
      case AttendanceDisplayStatus.notCheckedIn:
        return "Not Checked In";
      case AttendanceDisplayStatus.absent:
        return "Absent";
      case AttendanceDisplayStatus.onLeave:
        return "On Leave";
      case AttendanceDisplayStatus.halfDayLeave:
        return "Half Day Leave";
      case AttendanceDisplayStatus.holiday:
        return "Holiday";
      case AttendanceDisplayStatus.halfDayHoliday:
        return "Half Day Holiday";
    }
  }

  String get statusSubtitle {
    switch (displayStatus) {
      case AttendanceDisplayStatus.onLeave:
        return "Full day leave";
      case AttendanceDisplayStatus.halfDayLeave:
        return "Half day leave";
      case AttendanceDisplayStatus.holiday:
        return "Public holiday";
      case AttendanceDisplayStatus.halfDayHoliday:
        return "Half day holiday";
      case AttendanceDisplayStatus.absent:
        return "No attendance marked";
      case AttendanceDisplayStatus.notCheckedIn:
        return "Not checked in";
      default:
        return "—";
    }
  }

  Color get statusColor {
    switch (displayStatus) {
      case AttendanceDisplayStatus.working:
        return AppColors.infoColor;
      case AttendanceDisplayStatus.missingCheckout:
      case AttendanceDisplayStatus.absent:
        return AppColors.errorColor;
      case AttendanceDisplayStatus.notCheckedIn:
        return AppColors.labelTextColor;
      case AttendanceDisplayStatus.late:
        return AppColors.warningColor;
      case AttendanceDisplayStatus.onTime:
        return AppColors.successColor;
      case AttendanceDisplayStatus.onLeave:
      case AttendanceDisplayStatus.halfDayLeave:
      case AttendanceDisplayStatus.holiday:
      case AttendanceDisplayStatus.halfDayHoliday:
        return AppColors.primaryColor;
    }
  }

  IconData get statusIcon {
    switch (displayStatus) {
      case AttendanceDisplayStatus.working:
        return Icons.sync_rounded;
      case AttendanceDisplayStatus.missingCheckout:
        return Icons.warning_amber_rounded;
      case AttendanceDisplayStatus.late:
        return Icons.watch_later_rounded;
      case AttendanceDisplayStatus.onTime:
        return Icons.check_circle_rounded;
      case AttendanceDisplayStatus.notCheckedIn:
        return Icons.schedule_rounded;
      case AttendanceDisplayStatus.absent:
        return Icons.cancel_rounded;
      case AttendanceDisplayStatus.onLeave:
      case AttendanceDisplayStatus.halfDayLeave:
        return Icons.beach_access_rounded;
      case AttendanceDisplayStatus.holiday:
      case AttendanceDisplayStatus.halfDayHoliday:
        return Icons.celebration_rounded;
    }
  }
}