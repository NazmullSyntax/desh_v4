/// Build-time / runtime feature flags for the app.
///
/// [useFirebase] is the single switch between the real Firebase backend
/// and the in-memory mock backend used for offline development. Flip it
/// to `true` once `google-services.json` (Android) and
/// `GoogleService-Info.plist` (iOS) are added and `Firebase.initializeApp()`
/// has been called in `main.dart`.
class AppConfig {
  AppConfig._();

  static const bool useFirebase = false;

  /// Google Maps API key is read from platform manifests
  /// (AndroidManifest.xml / AppDelegate.swift / Info.plist), not from Dart
  /// code — see SETUP_INSTRUCTIONS.md for exact steps.
  static const String googleMapsApiKeyPlaceholder = 'YOUR_GOOGLE_MAPS_API_KEY';
}
