import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized typography. Using Poppins for headings (friendly, rounded,
/// modern travel-app feel) and Inter for body copy (very readable at small
/// sizes, good for dense info like opening hours / fees / distances).
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _heading({
    required double size,
    FontWeight weight = FontWeight.w600,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle _body({
    required double size,
    FontWeight weight = FontWeight.w400,
    required Color color,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  // ----------------- Light theme text styles -----------------
  static TextStyle h1Light = _heading(size: 32, weight: FontWeight.w700, color: AppColors.textPrimaryLight, height: 1.2);
  static TextStyle h2Light = _heading(size: 26, weight: FontWeight.w700, color: AppColors.textPrimaryLight, height: 1.25);
  static TextStyle h3Light = _heading(size: 22, weight: FontWeight.w600, color: AppColors.textPrimaryLight, height: 1.3);
  static TextStyle h4Light = _heading(size: 18, weight: FontWeight.w600, color: AppColors.textPrimaryLight, height: 1.3);
  static TextStyle bodyLargeLight = _body(size: 16, color: AppColors.textPrimaryLight, height: 1.5);
  static TextStyle bodyLight = _body(size: 14, color: AppColors.textPrimaryLight, height: 1.45);
  static TextStyle bodySmallLight = _body(size: 12, color: AppColors.textSecondaryLight, height: 1.4);
  static TextStyle captionLight = _body(size: 11, color: AppColors.textSecondaryLight, weight: FontWeight.w500);
  static TextStyle buttonLight = _heading(size: 15, weight: FontWeight.w600, color: Colors.white);

  // ----------------- Dark theme text styles -----------------
  static TextStyle h1Dark = _heading(size: 32, weight: FontWeight.w700, color: AppColors.textPrimaryDark, height: 1.2);
  static TextStyle h2Dark = _heading(size: 26, weight: FontWeight.w700, color: AppColors.textPrimaryDark, height: 1.25);
  static TextStyle h3Dark = _heading(size: 22, weight: FontWeight.w600, color: AppColors.textPrimaryDark, height: 1.3);
  static TextStyle h4Dark = _heading(size: 18, weight: FontWeight.w600, color: AppColors.textPrimaryDark, height: 1.3);
  static TextStyle bodyLargeDark = _body(size: 16, color: AppColors.textPrimaryDark, height: 1.5);
  static TextStyle bodyDark = _body(size: 14, color: AppColors.textPrimaryDark, height: 1.45);
  static TextStyle bodySmallDark = _body(size: 12, color: AppColors.textSecondaryDark, height: 1.4);
  static TextStyle captionDark = _body(size: 11, color: AppColors.textSecondaryDark, weight: FontWeight.w500);
  static TextStyle buttonDark = _heading(size: 15, weight: FontWeight.w600, color: Colors.white);
}
