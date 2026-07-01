/// Consistent spacing scale used everywhere instead of magic numbers.
/// Based on a 4px grid, which keeps paddings/margins visually rhythmic.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double screenPadding = 20;
  static const double cardPadding = 16;
  static const double sectionGap = 28;
}

/// Standard animation durations/curves so transitions feel consistent.
class AppDurations {
  AppDurations._();

  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 500);
  static const splash = Duration(milliseconds: 2200);
}
