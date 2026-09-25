import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// AttendEase — reusable Text widget.
/// Use this everywhere instead of raw `Text(...)` so font family
/// and default styling stay consistent app-wide.
class AppText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final TextDecoration? decoration;
  final Color? decorationColor;
  final double? decorationThickness;
  final List<Shadow>? shadows;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  final bool softWrap;
  final Widget? child;

  const AppText(
      this.text, {
        super.key,
        this.fontSize,
        this.fontWeight,
        this.fontStyle,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
        this.letterSpacing,
        this.wordSpacing,
        this.height,
        this.decoration,
        this.decorationColor,
        this.decorationThickness,
        this.shadows,
        this.padding,
        this.margin,
        this.alignment,
        this.softWrap = true,
        this.child,
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      margin: margin,
      padding: padding,
      child: child ??
          Text(
            text,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
            softWrap: softWrap,
            style: GoogleFonts.poppins(
              fontSize: fontSize ?? 15,
              fontWeight: fontWeight ?? FontWeight.w500,
              fontStyle: fontStyle,
              color: color ?? AppColors.headlineTextColor,
              letterSpacing: letterSpacing,
              wordSpacing: wordSpacing,
              height: height,
              decoration: decoration,
              decorationColor: decorationColor,
              decorationThickness: decorationThickness,
              shadows: shadows,
            ),
          ),
    );
  }
}

class HeadlineText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final TextAlign? textAlign;

  const HeadlineText(
      this.text, {
        super.key,
        this.fontSize = 20,
        this.color,
        this.textAlign,
      });

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.headlineTextColor,
      textAlign: textAlign,
    );
  }
}

/// Small caption/label preset — used under stat cards, timestamps,
/// "Applied on 15 Sep" style secondary text.
class CaptionText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;

  const CaptionText(
      this.text, {
        super.key,
        this.color,
        this.textAlign,
      });

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color ?? AppColors.labelTextColor,
      textAlign: textAlign,
    );
  }
}