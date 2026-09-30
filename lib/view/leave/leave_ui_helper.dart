import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../widget/app_colors.dart';

class LeaveUiHelper {
  static IconData iconForCode(String code) {
    switch (code.toUpperCase()) {
      case "CL":
        return Icons.wb_sunny_outlined;
      case "SL":
        return Icons.local_hospital_outlined;
      case "EL/PL":
      case "EL":
      case "PL":
        return Icons.flight_takeoff_rounded;
      case "LWP":
        return Icons.money_off_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  static Color colorForCode(String code) {
    switch (code.toUpperCase()) {
      case "CL":
        return AppColors.primaryColor;
      case "SL":
        return AppColors.errorColor;
      case "EL/PL":
      case "EL":
      case "PL":
        return AppColors.successColor;
      case "LWP":
        return AppColors.secondaryColor;
      default:
        return AppColors.labelTextColor;
    }
  }

  static String durationLabel(String leaveDurationType) {
    switch (leaveDurationType.toUpperCase()) {
      case "FULL_DAY":
        return 'leaves.duration_full_day'.tr();
      case "FIRST_HALF":
        return 'leaves.duration_first_half'.tr();
      case "SECOND_HALF":
        return 'leaves.duration_second_half'.tr();
      default:
        return leaveDurationType;
    }
  }
}