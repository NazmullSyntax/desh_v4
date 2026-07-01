import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../data/datasources/hotel_local_datasource.dart';
import '../data/repositories/firestore_favorites_repository.dart';
import '../data/repositories/mock_favorites_repository.dart';
import '../domain/repositories/favorites_repository.dart';
import '../models/hotel_model.dart';
import 'auth_provider.dart';

final hotelDataSourceProvider = Provider<HotelLocalDataSource>((ref) {
  return HotelLocalDataSource();
});

final allHotelsProvider = FutureProvider<List<Hotel>>((ref) async {
  return ref.watch(hotelDataSourceProvider).getAllHotels();
});

final hotelsForDistrictProvider = FutureProvider.family<List<Hotel>, String>((ref, districtId) async {
  return ref.watch(hotelDataSourceProvider).getHotelsForDistrict(districtId);
});

/// Provides the active [FavoritesRepository] implementation. Controlled
/// by [AppConfig.useFirebase], same as [authRepositoryProvider].
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirestoreFavoritesRepository();
  }
  return MockFavoritesRepository();
});

/// Streams the signed-in (or guest) user's favorited place IDs from
/// [FavoritesRepository]. Guests get their own scratch space (uid
/// `"guest"`) that simply won't persist across reinstalls — that's
/// expected, since there's no account to attach it to.
final favoritesStreamProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  final repo = ref.watch(favoritesRepositoryProvider);
  if (user == null) return Stream.value(<String>{});
  return repo.watchFavorites(user.uid);
});

/// Convenience provider exposing favorites as a plain `Set<String>` (never
/// loading/error states), so widgets that just want `.contains(id)` don't
/// need AsyncValue handling everywhere.
final favoritesProvider = Provider<Set<String>>((ref) {
  return ref.watch(favoritesStreamProvider).maybeWhen(data: (s) => s, orElse: () => <String>{});
});

/// Toggles a place's favorite status for the current user. This is a
/// function provider (not a StateNotifier) since the actual state lives
/// in [favoritesStreamProvider] / the repository — this just issues the
/// add/remove call.
final toggleFavoriteProvider = Provider<Future<void> Function(String)>((ref) {
  return (String placeId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(favoritesRepositoryProvider);
    final current = ref.read(favoritesProvider);
    if (current.contains(placeId)) {
      await repo.removeFavorite(user.uid, placeId);
    } else {
      await repo.addFavorite(user.uid, placeId);
    }
  };
});

/// Index of the selected tab in the main bottom navigation shell.
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
