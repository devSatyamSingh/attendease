import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ---------------- BRAND COLORS ----------------
  static const Color primaryColor = Color(0xFF4F46E5); // Indigo
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFFEEF0FF);
  static const Color secondaryColor = Color(0xFF14B8A6); // Teal accent
  static const Color secondaryDark = Color(0xFF0F766E);
  static const Color secondaryLight = Color(0xFFE6FFFB);

  // ---------------- NEUTRAL / TEXT ----------------
  static const Color headlineTextColor = Color(0xFF111827);
  static const Color bodyTextColor = Color(0xFF374151);
  static const Color labelTextColor = Color(0xFF6B7280);
  static const Color placeholderColor = Color(0xFF9CA3AF);

  // ---------------- BASE ----------------
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF000000);
  static const Color scaffoldBgColor = Color(0xFFF9FAFB);
  static const Color cardBgColor = Color(0xFFFFFFFF);
  static const Color fieldFillColor = Color(0xFFF3F4F6);

  // ---------------- BORDERS / DIVIDERS ----------------
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFE5E7EB);

  // ---------------- DISABLED STATES ----------------
  // Used by AppButton / AppTextField so a disabled control looks
  // clearly "off", not just a faded primary color.
  static const Color disabledColor = Color(0xFFD1D5DB);
  static const Color disabledTextColor = Color(0xFF9CA3AF);

  // ---------------- GENERIC STATUS COLORS ----------------
  static const Color successColor = Color(0xFF16A34A);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF3B82F6);

  // ---------------- ATTENDANCE STATUS COLORS ----------------
  static const Color workingColor = Color(0xFF16A34A); // WORKING
  static const Color checkedOutColor = Color(0xFF3B82F6); // CHECKED_OUT
  static const Color notCheckedInColor = Color(0xFF9CA3AF); // NOT_CHECKED_IN
  static const Color lateColor = Color(0xFFF59E0B); // late minutes
  static const Color earlyColor = Color(0xFF3B82F6); // early checkout
  static const Color missingColor = Color(0xFFEF4444); // CHECKOUT_MISSING
  static const Color absentColor = Color(0xFFEF4444); // ABSENT
  static const Color leaveColor = Color(0xFF8B5CF6); // ON_LEAVE / HALF_DAY_LEAVE
  static const Color holidayColor = Color(0xFF06B6D4); // HOLIDAY
  static const Color weekendColor = Color(0xFF9CA3AF); // WEEKEND

  // ---------------- REQUEST STATUS (LEAVE / DEVICE CHANGE) ----------------
  static const Color pendingColor = Color(0xFFF59E0B);
  static const Color approvedColor = Color(0xFF16A34A);
  static const Color rejectedColor = Color(0xFFEF4444);
  static const Color cancelledColor = Color(0xFF9CA3AF);

  // ---------------- GRADIENTS ----------------
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Single source of truth for attendance-status -> color mapping.
  /// Use this in dashboard/history/report instead of writing a
  /// switch-statement in every screen.
  static Color attendanceStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WORKING':
      case 'CHECKED_IN':
        return workingColor;
      case 'CHECKED_OUT':
        return checkedOutColor;
      case 'NOT_CHECKED_IN':
        return notCheckedInColor;
      case 'CHECKOUT_MISSING':
        return missingColor;
      case 'ABSENT':
        return absentColor;
      case 'ON_LEAVE':
      case 'HALF_DAY_LEAVE':
        return leaveColor;
      case 'HOLIDAY':
      case 'HALF_DAY_HOLIDAY':
        return holidayColor;
      case 'WEEKEND':
        return weekendColor;
      default:
        return labelTextColor;
    }
  }

  /// Single source of truth for leave / device-change request status colors.
  static Color requestStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return pendingColor;
      case 'APPROVED':
      case 'ACTIVE':
        return approvedColor;
      case 'REJECTED':
      case 'REVOKED':
        return rejectedColor;
      case 'CANCELLED':
        return cancelledColor;
      default:
        return labelTextColor;
    }
  }
}