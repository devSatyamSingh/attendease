import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../model/attendance_model.dart';
import '../../widget/app_colors.dart';

extension AttendanceStatusUi on AttendanceModel {
  String get statusLabel {
    switch (displayStatus) {
      case AttendanceDisplayStatus.working:
        return 'attendance_status.working'.tr();
      case AttendanceDisplayStatus.missingCheckout:
        return 'attendance_status.missing_checkout'.tr();
      case AttendanceDisplayStatus.late:
        return 'attendance_status.late_by'.tr(args: ['${lateMinutes ?? 0}']);
      case AttendanceDisplayStatus.onTime:
        return 'attendance_status.on_time'.tr();
      case AttendanceDisplayStatus.notCheckedIn:
        return 'attendance_status.not_checked_in'.tr();
      case AttendanceDisplayStatus.absent:
        return 'attendance_status.absent'.tr();
      case AttendanceDisplayStatus.onLeave:
        return 'attendance_status.on_leave'.tr();
      case AttendanceDisplayStatus.halfDayLeave:
        return 'attendance_status.half_day_leave'.tr();
      case AttendanceDisplayStatus.holiday:
        return 'attendance_status.holiday'.tr();
      case AttendanceDisplayStatus.halfDayHoliday:
        return 'attendance_status.half_day_holiday'.tr();
    }
  }

  String get statusSubtitle {
    switch (displayStatus) {
      case AttendanceDisplayStatus.onLeave:
        return 'attendance_status.sub_full_day_leave'.tr();
      case AttendanceDisplayStatus.halfDayLeave:
        return 'attendance_status.sub_half_day_leave'.tr();
      case AttendanceDisplayStatus.holiday:
        return 'attendance_status.sub_public_holiday'.tr();
      case AttendanceDisplayStatus.halfDayHoliday:
        return 'attendance_status.sub_half_day_holiday'.tr();
      case AttendanceDisplayStatus.absent:
        return 'attendance_status.sub_no_attendance'.tr();
      case AttendanceDisplayStatus.notCheckedIn:
        return 'attendance_status.sub_not_checked_in'.tr();
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