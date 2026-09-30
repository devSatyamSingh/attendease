import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

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
    final lang = Localizations.localeOf(context).languageCode;
    final isUrdu = lang == 'ur';

    final size = fontSize ?? 15;
    final weight = fontWeight ?? FontWeight.w500;
    final textColor = color ?? AppColors.headlineTextColor;

    // Urdu (Nastaliq) ki line height badi hoti hai, warna text cut hota hai.
    // Letter spacing Urdu me kabhi nahi lagani (akshar jud kar likhe jaate hain).
    final TextStyle style = isUrdu
        ? TextStyle(
      fontFamily: 'NotoNastaliqUrdu',
      fontSize: size,
      fontWeight: weight,
      fontStyle: fontStyle,
      color: textColor,
      wordSpacing: wordSpacing,
      height: height ?? 1.7,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationThickness: decorationThickness,
      shadows: shadows,
    )
        : GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      fontStyle: fontStyle,
      color: textColor,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationThickness: decorationThickness,
      shadows: shadows,
    );

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
            style: style,
          ),
    );
  }
}

class HeadlineText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const HeadlineText(
      this.text, {
        super.key,
        this.fontSize = 20,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
      });

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.headlineTextColor,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class CaptionText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const CaptionText(
      this.text, {
        super.key,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
      });

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color ?? AppColors.labelTextColor,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}