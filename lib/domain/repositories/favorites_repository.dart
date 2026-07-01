/// Domain-layer contract for persisting a user's favorited tourist place
/// IDs. Kept as a simple set of strings — the actual [TouristPlace] data
/// is always re-fetched from the (offline-first) travel guide, never
/// duplicated into the favorites store.
abstract class FavoritesRepository {
  Stream<Set<String>> watchFavorites(String userId);

  Future<void> addFavorite(String userId, String placeId);

  Future<void> removeFavorite(String userId, String placeId);
}
