import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';


class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final int? maxLength;
  final int? maxLines;
  final bool readOnly;
  final bool enabled;
  final bool obscureText;
  final bool filled;
  final Color? cursorColor;
  final bool showBorder;
  final String? hintText;
  final String? labelText;
  final String? prefixText;
  final String? suffixText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusBorderColor;
  final double? borderRadius;
  final double? contentPadding;
  final EdgeInsetsGeometry? margin;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final void Function()? onTap;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    this.controller,
    this.keyboardType,
    this.focusNode,
    this.maxLength,
    this.cursorColor,
    this.maxLines = 1,
    this.readOnly = false,
    this.enabled = true,
    this.obscureText = false,
    this.filled = true,
    this.showBorder = true,
    this.hintText,
    this.labelText,
    this.prefixText,
    this.suffixText,
    this.prefixIcon,
    this.suffixIcon,
    this.style,
    this.hintStyle,
    this.labelStyle,
    this.fillColor,
    this.borderColor,
    this.focusBorderColor,
    this.borderRadius,
    this.contentPadding,
    this.margin,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        focusNode: focusNode,
        maxLength: maxLength,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        cursorColor: cursorColor ?? AppColors.primaryColor,
        readOnly: readOnly,
        enabled: enabled,
        obscureText: obscureText,
        onChanged: onChanged,
        onTap: onTap,
        validator: validator,
        style: style ??
            GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: enabled
                  ? AppColors.headlineTextColor
                  : AppColors.disabledTextColor,
            ),
        decoration: InputDecoration(
          counterText: "",
          filled: filled,
          fillColor: enabled
              ? (fillColor ?? AppColors.fieldFillColor)
              : AppColors.fieldFillColor.withOpacity(.6),
          hintText: hintText,
          labelText: labelText,
          prefixText: prefixText,
          suffixText: suffixText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          hintStyle: hintStyle ??
              GoogleFonts.poppins(
                color: AppColors.placeholderColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
          labelStyle: labelStyle ??
              GoogleFonts.poppins(
                color: AppColors.labelTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: contentPadding ?? 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 16),
            borderSide: showBorder
                ? BorderSide(color: borderColor ?? AppColors.borderColor, width: 1)
                : BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 16),
            borderSide: showBorder
                ? BorderSide(color: borderColor ?? AppColors.borderColor, width: 1)
                : BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 16),
            borderSide: BorderSide(
              color: focusBorderColor ?? AppColors.primaryColor,
              width: 1.4,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 16),
            borderSide: BorderSide(
              color: (borderColor ?? AppColors.borderColor).withOpacity(.6),
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 16),
            borderSide: const BorderSide(color: AppColors.errorColor, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 16),
            borderSide: const BorderSide(color: AppColors.errorColor, width: 1.2),
          ),
        ),
      ),
    );
  }
}