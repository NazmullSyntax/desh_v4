import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_user_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/guide/district_detail_screen.dart';
import '../../screens/guide/place_detail_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/ai_assistant/ai_assistant_screen.dart';
import '../../screens/safety/safety_screen.dart';
import '../../screens/hotels/hotel_detail_screen.dart';
import '../../screens/hotels/hotel_list_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/weather/weather_screen.dart';
import '../../screens/favorites/favorites_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/bookings/bookings_screen.dart';
import '../../screens/groups/group_detail_screen.dart';
import '../../screens/groups/my_groups_screen.dart';

/// Route path constants, kept in one place to avoid typo-prone string
/// literals scattered across the codebase.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  static const home = '/home';
  static const guide = '/guide';
  static const tripPlanner = '/trip-planner';
  static const aiAssistant = '/ai-assistant';
  static const favorites = '/favorites';
  static const profile = '/profile';

  static const districtDetail = '/guide/district';
  static const placeDetail = '/guide/place';
  static const hotelList = '/hotels';
  static const hotelDetail = '/hotels/detail';
  static const safety = '/safety';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const weather = '/weather';
  static const editProfile = '/profile/edit';
  // Note: `checkout` is intentionally NOT registered as a GoRoute. It's
  // reached via Navigator.push with typed Dart objects (DateTime, enums,
  // doubles) that don't serialize cleanly into URL query params — same
  // pattern as PlaceMapScreen / DistrictListScreen elsewhere in this app.
  static const checkout = '/checkout';
  static const bookings = '/bookings';
  static const groupDetail = '/groups/detail';
  static const myGroups = '/groups/mine';
  // Note: `groupsForPlace` and `createGroup` are intentionally NOT
  // registered as GoRoutes — same reasoning as `checkout` above. They need
  // a destination's full display info (name + image), which don't
  // serialize cleanly into URL query params, so they're reached via
  // Navigator.push with typed Dart objects from PlaceDetailScreen.
}

/// Builds the app [GoRouter], reacting to auth state for redirects (e.g.
/// kicking signed-out users back to login when they hit a protected route).
GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.maybeWhen(data: (u) => u != null, orElse: () => false);
      final isAuthRoute = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.onboarding,
        AppRoutes.splash,
      ].contains(state.matchedLocation);

      // Still resolving the auth stream — let the splash screen handle it.
      if (authState.isLoading && state.matchedLocation == AppRoutes.splash) {
        return null;
      }

      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }
      if (isLoggedIn && (state.matchedLocation == AppRoutes.login || state.matchedLocation == AppRoutes.register)) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),

      // Main app shell with bottom navigation — Home / Guide / Trip Planner
      // / AI Assistant / Profile each render inside this persistent shell.
      GoRoute(path: AppRoutes.home, builder: (context, state) => const MainShell(initialIndex: 0)),
      GoRoute(path: AppRoutes.guide, builder: (context, state) => const MainShell(initialIndex: 1)),
      GoRoute(path: AppRoutes.tripPlanner, builder: (context, state) => const MainShell(initialIndex: 2)),
      GoRoute(path: AppRoutes.aiAssistant, builder: (context, state) => const AiAssistantScreen()),
      GoRoute(path: AppRoutes.profile, builder: (context, state) => const MainShell(initialIndex: 3)),

      GoRoute(
        path: AppRoutes.districtDetail,
        builder: (context, state) {
          final districtId = state.uri.queryParameters['id'] ?? '';
          return DistrictDetailScreen(districtId: districtId);
        },
      ),
      GoRoute(
        path: AppRoutes.placeDetail,
        builder: (context, state) {
          final placeId = state.uri.queryParameters['id'] ?? '';
          return PlaceDetailScreen(placeId: placeId);
        },
      ),
      GoRoute(path: AppRoutes.hotelList, builder: (context, state) => const HotelListScreen()),
      GoRoute(
        path: AppRoutes.hotelDetail,
        builder: (context, state) {
          final hotelId = state.uri.queryParameters['id'] ?? '';
          return HotelDetailScreen(hotelId: hotelId);
        },
      ),
      GoRoute(path: AppRoutes.safety, builder: (context, state) => const SafetyScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
      GoRoute(path: AppRoutes.weather, builder: (context, state) => const WeatherScreen()),
      GoRoute(path: AppRoutes.favorites, builder: (context, state) => const FavoritesScreen()),
      GoRoute(path: AppRoutes.editProfile, builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: AppRoutes.bookings, builder: (context, state) => const BookingsScreen()),
      GoRoute(
        path: AppRoutes.groupDetail,
        builder: (context, state) {
          final groupId = state.uri.queryParameters['id'] ?? '';
          return GroupDetailScreen(groupId: groupId);
        },
      ),
      GoRoute(path: AppRoutes.myGroups, builder: (context, state) => const MyGroupsScreen()),
    ],
  );
}

/// Exposes the app's [GoRouter] instance through Riverpod so redirects can
/// read live auth state.
final routerProvider = Provider<GoRouter>((ref) {
  return buildRouter(ref);
});

/// Re-export for screens that just need the [AppUser] type alongside routes.
typedef RouterAppUser = AppUser;
