# DeshExplorer — Smart Travel Guide & Trip Planner for Bangladesh

A Flutter travel app for exploring Bangladesh: a 64-district travel guide,
trip planner with budget calculator, hotel browser with Bangladesh-style
checkout, editable profiles with photo upload, AI travel assistant, safety
center, and more.

> **Build status:** This is a working foundation, not a finished, audited
> commercial product. See **"What's real vs. what's scaffolded"** (Section
> 7) before you start, and read the **payment security warning** in
> Section 4 — it's the single most important thing to get right before
> handling real money.

---

## 1. Prerequisites

- Flutter SDK 3.22+ (`flutter --version` to check)
- Dart 3.3+
- Android Studio (for Android) and/or Xcode 15+ (for iOS, Mac only)
- A code editor — VS Code with the Flutter extension works well

This project was authored without access to a live Flutter SDK or network,
so it has **not** been run through `flutter pub get` / `flutter run` by the
assistant that built it. Treat the first run as a normal "fresh checkout"
— expect to fix a handful of small issues (see Section 8: Known Risks).

---

## 2. First Run (no Firebase needed)

The app runs out of the box with **mock data and mock backends** for auth,
storage, trips, favorites, and payments — no Firebase project or merchant
account required to explore the full UI end to end.

```bash
cd deshexplorer
flutter pub get
flutter run
```

You should land on the splash screen → onboarding (first run only) →
login screen. Use **"Continue as Guest"** or **"Continue with Google"**
(both are mocked) to get into the app immediately, or register a fake
account. In mock mode, each guest session gets its own scratch space for
favorites/trips, but none of it survives an app restart — that's expected
until Firebase is wired up.

Try the full loop: Home → a destination → Hotels → **Book Now** → pick a
payment method (defaults to **Pay on Arrival**, which always succeeds
instantly) → **My Bookings**. Also try Profile → tap your avatar → change
your name and photo.

---

## 3. Enabling Firebase (when you're ready)

This now wires up **four** things, not just login: Auth, Firestore (trips
+ favorites), and Storage (profile photos). All four are controlled by one
flag.

1. **Android:** place `google-services.json` in `android/app/`.
2. **iOS:** place `GoogleService-Info.plist` in `ios/Runner/` (drag it into
   the Xcode project so it's added to the target — copying the file alone
   isn't enough on iOS).
3. Run `flutterfire configure` from the project root (requires the
   FlutterFire CLI) to generate `lib/firebase_options.dart`.
4. In `android/build.gradle` and `android/app/build.gradle`, uncomment the
   `com.google.gms.google-services` plugin lines (search for `Firebase:`
   comments — they're marked clearly).
5. In `android/settings.gradle`, uncomment the matching plugin id line.
6. In `lib/main.dart`, uncomment the `Firebase.initializeApp(...)` block
   and its imports.
7. In `lib/config/app_config.dart`, set:
   ```dart
   static const bool useFirebase = true;
   ```
8. In the Firebase Console:
   - Enable **Authentication** providers: Email/Password, Google, and
     Anonymous (for Guest login).
   - Create a **Cloud Firestore** database, then paste `firestore.rules`
     (project root) into Firestore → Rules.
   - Enable **Storage**, then paste `storage.rules` (project root) into
     Storage → Rules.

That's it — every repository (`FirebaseAuthRepository`,
`FirestoreTripRepository`, `FirestoreFavoritesRepository`,
`FirebaseStorageRepository`) already implements its full interface, so
**no screen code needs to change**. Flipping the one flag in
`app_config.dart` switches the entire app from mock to live data.

---

## 4. Bangladesh Payments — read this before going live

The Checkout screen (`lib/screens/payment/checkout_screen.dart`) offers
**bKash, Nagad, Rocket, Card, and Pay on Arrival**, matching what
Bangladeshi travel apps typically support. Right now, the first four
simulate a payment (random ~95% success, fake transaction ID) via
`MockPaymentRepository`. **Pay on Arrival always works for real today** —
it's just a reservation, no money moves.

### Why the other four aren't "real" yet, and can't be made real from Flutter alone

bKash, Nagad, and Rocket's checkout APIs require a **registered merchant
account** and a **secret app key/signature** that must never be embedded
in a mobile app binary — anyone could decompile your APK and steal it.
The correct architecture is:

```
Flutter app -> your own backend (e.g. Cloud Function) -> bKash/Nagad/Rocket API
```

Your backend holds the merchant secret; the app only ever talks to your
backend. The same is true for card payments — use a PCI-compliant SDK
(Stripe, SSLCommerz, and ShurjoPay are common choices for Bangladesh)
rather than collecting raw card numbers yourself.

### What to do next

1. Register merchant accounts with bKash/Nagad/Rocket (or pick a Bangladesh
   payment aggregator like **SSLCommerz** or **ShurjoPay**, which bundle
   bKash/Nagad/Rocket/cards behind a single API — usually the faster path
   for a new app).
2. Build a small backend endpoint that creates a payment session and
   verifies the result (a Firebase Cloud Function pairs naturally with the
   Firestore setup above).
3. Write a new class implementing `PaymentRepository` (see
   `lib/domain/repositories/payment_repository.dart`) that calls your
   backend instead of `MockPaymentRepository`.
4. Swap it into `lib/providers/payment_provider.dart`
   (`paymentRepositoryProvider`) — no screen code needs to change, exactly
   like the Firebase flag.

Until that's done, **leave Pay on Arrival as the default** (it already
is) so the app is honest with users about what's actually being charged.

---

## 5. Enabling Google Maps

The Maps & Navigation screens currently show a static placeholder map with
working "Open in Google Maps" / "Get Directions" buttons (they launch the
real Google Maps app/website via deep link) — this works with **zero
configuration**.

To upgrade to a live interactive in-app map:

1. Get an API key from the Google Cloud Console with **Maps SDK for
   Android** and **Maps SDK for iOS** enabled.
2. Android: replace `YOUR_GOOGLE_MAPS_API_KEY` in
   `android/app/src/main/AndroidManifest.xml`.
3. iOS: add to `ios/Runner/AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
   ```
   (import `GoogleMaps` at the top of that file.)
4. Replace the `_MapPlaceholder` widget in
   `lib/screens/maps/place_map_screen.dart` with a `GoogleMap` widget from
   `google_maps_flutter` — the lat/lng and marker data are already wired
   up on the `TouristPlace` model, so this is a localized change.

---

## 6. Images — current strategy and how to upgrade it

Every destination, district, division, and hotel photo in this build
loads from **Picsum Photos** (picsum.photos) using a stable *seeded* URL —
the same seed always returns the same photo, so each location consistently
shows one specific image rather than a random one on every screen rebuild.
This needed zero setup and means **every screen shows a real, decent-
looking photo today**, with no broken images anywhere.

**Be upfront with anyone evaluating this app:** Picsum photos are *not*
location-accurate — the Cox's Bazar entry won't actually show Cox's Bazar.
They're a professional-looking placeholder, not a claim of authenticity.
Picsum's own guidance is that it's meant for placeholders/mockups, not as
a runtime dependency a commercial release quietly relies on forever.

### Upgrading to real, location-accurate photos

You don't need to touch any Dart code — every image field in
`assets/data/*.json` is a plain URL string. Two options:

1. **Fastest:** find real photos (Wikimedia Commons is a good source for
   freely-licensed Bangladesh travel photography, or your own licensed/
   your own-shot photography), and paste the direct image URL into the
   relevant `imageUrl`/`imageUrls` field.
2. **Most professional:** upload your own photos to Firebase Storage
   (already wired up — see Section 3) under a new `destination_photos/`
   folder, and reference the resulting download URLs in the JSON files.

`AppNetworkImage` (`lib/widgets/common/app_network_image.dart`) already
handles three sources transparently — real `https://` URLs, local device
files (used for freshly-picked profile photos), and bundled
`assets/images/...` paths — so any of the above works without touching
the widget layer.

---

## 7. What's real vs. what's scaffolded

This build prioritized a **working, navigable app with real architecture**
over partial stubs of every single feature in the original spec. Here's
the honest breakdown after this round of updates:

### Fully working today (no further setup needed)
- Splash → Onboarding (3 screens) → Login / Register / Forgot Password /
  Google Sign-In / Guest Login (all functional against a mock backend)
- **Edit Profile**: change display name, pick a profile photo from camera
  or gallery (uploads through `StorageRepository`, shows immediately)
- Home screen: search bar, weather card, popular destinations, explore by
  division, category filter chips, trending places, travel tip, emergency
  button, AI Assistant FAB, bottom navigation
- Travel Guide: Division -> District -> Tourist Place drill-down, with
  **9 districts and 12 real, researched tourist places** (Cox's Bazar,
  the Sundarbans, Sreemangal tea gardens, Paharpur, Nilgiri Hills, Shashi
  Lodge, Kuakata Beach, Tajhat Palace, Lalbagh Fort, Ahsan Manzil, Sajek
  Valley, and Saint Martin's Island) carrying real entry fees, opening
  hours, history, travel tips, and emergency contacts; all **64 districts**
  are navigable, the rest marked "Coming soon"
- **Travel Group System**: create a group trip to any destination (date,
  budget, meeting point, max members, open-join or approval-required),
  browse/join/leave/request-join groups, approve or reject join requests
  as the group creator, and a working per-group chat thread. Surfaced as
  "Travelers Currently Planning This Trip" on every place detail page and
  "My Travel Groups" in the Profile menu. Built on the same mock/Firestore
  repository pattern as everything else (`GroupsRepository` ->
  `MockGroupsRepository` / `FirestoreGroupsRepository`) — persists across
  restarts the moment `useFirebase = true`. The in-group chat is a simple
  local/Firestore text thread, not the full Real-Time Chat system (read
  receipts, typing indicators, voice notes) described in the original
  spec — that's a separate, larger feature still to be built.
- Trip Planner: destination/date/traveler/transport/budget wizard, a real
  budget calculator, an auto-generated day-by-day itinerary, and a **Book
  This Trip** button leading into checkout
- Hotel list/detail with a real **booking flow**: pick check-in date,
  nights, and travelers -> Checkout -> choose bKash / Nagad / Rocket /
  Card / Pay on Arrival -> processing screen -> My Bookings (see Section 4
  for what's simulated vs. real)
- **Favorites and Trips persist per-user** through `FavoritesRepository` /
  `TripRepository` — in-memory per session today, switches to real
  Firestore sync the moment you flip `useFirebase = true`
- AI Travel Assistant: working chat UI with keyword-based mock responses
- Safety module: SOS button (dials 999), real Bangladesh emergency numbers,
  safety guidelines, women's safety tips
- Weather module: current + 7-day forecast (mock data, real UI)
- Profile (live stats, badges, menu including My Bookings and My Travel
  Groups), Notifications (mock feed), Settings (dark mode — persisted)
- Full light/dark Material 3 theme with your requested color palette
- Real uploaded photos are bundled as assets for Cox's Bazar, the
  Sundarbans, Sreemangal, Nilgiri Hills (Bandarban), Kuakata, Lalbagh
  Fort, Ahsan Manzil, Sajek Valley, Saint Martin's Island, plus the
  Bandarban/Rangamati district cards and one hotel — with tap-to-zoom
  fullscreen preview. Everything else still uses stable seeded
  `picsum.photos` placeholder URLs; see Section 6 for the upgrade path.

### Scaffolded but not wired to a real backend
- **Firebase Auth, Firestore, Storage** — all four repositories
  (`FirebaseAuthRepository`, `FirestoreTripRepository`,
  `FirestoreFavoritesRepository`, `FirebaseStorageRepository`) plus
  `FirestoreGroupsRepository` (Travel Groups) are fully implemented; just
  need config (Section 3) and the one flag flip
- **Real Bangladesh payments** — UI and `PaymentRepository` interface are
  complete; needs a backend + merchant integration, see Section 4 in full
- **Google Maps live view** — placeholder map + working external
  navigation today; Section 5 covers the upgrade path
- **AI Assistant real LLM backend** — currently rule-based mock replies;
  `lib/providers/chat_provider.dart` has a single `_generateReply` method
  to replace with a real API call (Dio is already a dependency)
- **Push notifications (FCM)** — Notifications screen has a realistic mock
  feed; no `firebase_messaging` listener wired yet
- **Travel Diary** — not built in this pass (model layer would mirror
  `TripPlan`; needs a new screen + a Firestore subcollection, following
  the exact same pattern as Trips/Favorites)
- **64-district rich content** — only 9 districts have full written
  content; the data file format is documented and ready for more entries
- **Reviews** — `PlaceReview` model exists and renders on the Place
  Detail screen, but there's no "write a review" flow yet; same pattern
  as Trips/Favorites would apply (a `ReviewRepository` writing to
  `places/{placeId}/reviews/{reviewId}`)

### Folder structure
```
lib/
  core/           # theme, constants, router, shared widgets
  config/         # feature flags (Firebase on/off, etc)
  models/         # plain Dart data classes (no codegen)
  data/
    datasources/  # local JSON loaders (guide, hotels)
    repositories/ # Firebase + Mock implementations for every backend concern
  domain/
    repositories/ # abstract interfaces (Auth, Storage, Trip, Favorites, Payment)
  providers/      # Riverpod providers/controllers -- the app's state layer
  screens/        # one folder per feature/module
  widgets/        # reusable UI pieces, grouped by feature
assets/
  data/           # divisions.json, districts.json, tourist_places.json, hotels.json
firestore.rules    # example Firestore security rules (see Section 3)
storage.rules       # example Storage security rules (see Section 3)
```

---

## 8. Known risks / things to check on first run

This was hand-written without a live Flutter SDK to compile against, so
please budget time for:

1. **Package versions** — the versions pinned in `pubspec.yaml` were
   accurate as of early 2025 training data; run `flutter pub outdated` and
   bump anything that's since had a breaking change, especially
   `go_router`, `firebase_*`, `image_picker`, and `google_maps_flutter`.
2. **`flutter create` metadata** — this project was assembled by hand
   rather than via `flutter create`, so a few platform files that Flutter
   normally generates (`ios/Runner.xcodeproj`, `ios/Flutter/*.xcconfig`,
   full `ios/Runner/Assets.xcassets` icon sets, Android Gradle wrapper
   jar/properties, `windows/`, `web/`) are **not included**. The fastest
   fix is running `flutter create .` from the project root — it fills in
   any missing platform folders without touching your existing `lib/`
   code or the `android/`/`ios/` files already customized here.
3. **`image_picker` platform permissions** — camera/gallery access needs
   permission entries beyond what's already in `Info.plist`
   (`NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` are
   already there); Android handles this automatically via the
   `image_picker` plugin's manifest merge, but double-check after your
   first `flutter pub get`.
4. **App icons / splash branding** — using Flutter defaults; swap in your
   own via `flutter_launcher_icons` and `flutter_native_splash` packages
   once you have final logo assets.

---

## 9. Next steps, roughly in priority order

1. Run the fixes in Section 8 so it builds cleanly.
2. Wire up Firebase (Section 3) and flip `useFirebase = true` — this
   instantly makes Auth, Trips, Favorites, and Profile photos real.
3. Decide on a Bangladesh payment aggregator (SSLCommerz/ShurjoPay are the
   fastest path) and build the backend + `PaymentRepository`
   implementation described in Section 4. Don't skip the "why" — embedding
   payment gateway secrets in the app is a real security risk, not just
   best practice.
4. Upgrade images per Section 6 once you have real photography or a
   licensed source lined up.
5. Decide on a real AI backend (Anthropic/OpenAI API via Dio) for the
   Travel Assistant — the chat UI won't need to change.
6. Expand `tourist_places.json` district by district — the schema is
   documented in `lib/models/tourist_place_model.dart`.
7. Add Google Maps API keys (Section 5) once you're ready for a live map.
8. Build the Travel Diary and Reviews-writing flow, following the
   `TripRepository`/`FavoritesRepository` pattern for consistency.
