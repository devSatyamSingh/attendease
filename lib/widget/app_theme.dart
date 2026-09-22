import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';


class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.scaffoldBgColor,
    primaryColor: AppColors.primaryColor,
    fontFamily: GoogleFonts.poppins().fontFamily,

    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      surface: AppColors.cardBgColor,
      error: AppColors.errorColor,
      onPrimary: AppColors.whiteColor,
      onSecondary: AppColors.whiteColor,
      onSurface: AppColors.headlineTextColor,
      onError: AppColors.whiteColor,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.scaffoldBgColor,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppColors.headlineTextColor),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.headlineTextColor,
      ),
    ),

    textTheme: TextTheme(
      headlineLarge: GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.headlineTextColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.headlineTextColor,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.bodyTextColor,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.labelTextColor,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.placeholderColor,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fieldFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: GoogleFonts.poppins(
        color: AppColors.placeholderColor,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.errorColor, width: 1.2),
      ),
    ),

    // Disabled buttons get a distinct gray fill + gray text
    // (AppButton also implements its own disabled styling directly,
    // this covers plain ElevatedButton usage elsewhere in the app).
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        disabledBackgroundColor: AppColors.disabledColor,
        foregroundColor: AppColors.whiteColor,
        disabledForegroundColor: AppColors.disabledTextColor,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        side: const BorderSide(color: AppColors.primaryColor, width: 1.4),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.dividerColor,
      thickness: 1,
      space: 1,
    ),

    cardTheme: CardThemeData(
      color: AppColors.cardBgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.whiteColor,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.placeholderColor,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      elevation: 8,
    ),
  );
}