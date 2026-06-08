import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle get displayH1 => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.6,
        color: AppColors.textPrimary,
      );

  static TextStyle get splashTitle => GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
        color: Colors.white,
      );

  static TextStyle get screenTitle => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get sectionLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.65,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.65,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLight => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w300,
        height: 1.7,
        color: AppColors.textPrimary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get chipLabel => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get buttonLabel => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get aiAccent => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.softPurple,
        letterSpacing: 0.5,
      );
}
