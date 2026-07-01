import 'package:flutter/material.dart';

/// Central color palette for DeshExplorer.
///
/// Primary  -> Deep Green   (#0F9D58) — trust, nature, Bangladesh's green fields
/// Secondary-> Sky Blue     (#4A90D9) — calm, sky/water, travel & freedom
/// Accent   -> Golden Yellow(#F4B400) — warmth, sun, highlights & CTAs
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0F9D58);
  static const Color primaryDark = Color(0xFF0B7A43);
  static const Color primaryLight = Color(0xFF4CBB7D);

  static const Color secondary = Color(0xFF4A90D9);
  static const Color secondaryDark = Color(0xFF2E6CB0);
  static const Color secondaryLight = Color(0xFF89B8E8);

  static const Color accent = Color(0xFFF4B400);
  static const Color accentDark = Color(0xFFC8920A);

  // Light theme neutrals
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE7E9EC);
  static const Color textPrimaryLight = Color(0xFF1B1F23);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Dark theme neutrals
  static const Color backgroundDark = Color(0xFF101314);
  static const Color surfaceDark = Color(0xFF1A1F1E);
  static const Color cardDark = Color(0xFF202625);
  static const Color borderDark = Color(0xFF2C3331);
  static const Color textPrimaryDark = Color(0xFFF3F5F4);
  static const Color textSecondaryDark = Color(0xFFA3ACA9);

  // Status colors
  static const Color success = Color(0xFF0F9D58);
  static const Color warning = Color(0xFFF4B400);
  static const Color error = Color(0xFFE34B4B);
  static const Color info = Color(0xFF4A90D9);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F9D58), Color(0xFF0B7A43)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFF4B400), Color(0xFFE3852B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient skyGradient = LinearGradient(
    colors: [Color(0xFF4A90D9), Color(0xFF2E6CB0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Glassmorphism overlay tint used on top of imagery (cards, headers).
  static Color glass({bool dark = false}) =>
      (dark ? Colors.black : Colors.white).withOpacity(0.12);
}
