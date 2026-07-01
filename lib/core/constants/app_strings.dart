/// Static, non-localized strings used in multiple places across the app.
/// (Full i18n is handled later via the Settings > Language module; this
/// file holds the English defaults and app-level constants.)
class AppStrings {
  AppStrings._();

  static const String appName = 'DeshExplorer';
  static const String appTagline = 'Smart Travel Guide & Trip Planner for Bangladesh';

  // Onboarding
  static const String onboardTitle1 = 'Discover Bangladesh';
  static const String onboardBody1 =
      'Explore 64 districts packed with beaches, hills, rivers, and heritage sites — all in one app.';

  static const String onboardTitle2 = 'Plan Smarter Trips';
  static const String onboardBody2 =
      'Build day-by-day itineraries, estimate your budget, and book transport and stays with confidence.';

  static const String onboardTitle3 = 'Travel Safely';
  static const String onboardBody3 =
      'Emergency contacts, safety tips, and an AI travel assistant — wherever your journey takes you.';

  // Auth
  static const String welcomeBack = 'Welcome back';
  static const String loginSubtitle = 'Log in to continue exploring Bangladesh';
  static const String createAccount = 'Create your account';
  static const String registerSubtitle = 'Join thousands of travelers exploring Bangladesh';
  static const String forgotPasswordTitle = 'Reset your password';
  static const String forgotPasswordSubtitle =
      "Enter the email associated with your account and we'll send a reset link.";

  // Errors (generic, user-facing copy)
  static const String genericError = 'Something went wrong. Please try again.';
  static const String noInternet = 'No internet connection. Showing saved data where available.';
}
