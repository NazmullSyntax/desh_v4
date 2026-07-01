import 'dart:async';
import '../../domain/repositories/favorites_repository.dart';

/// In-memory mock implementation of [FavoritesRepository], used until
/// Firebase is configured.
class MockFavoritesRepository implements FavoritesRepository {
  final Map<String, Set<String>> _favoritesByUser = {};
  final Map<String, StreamController<Set<String>>> _controllers = {};

  StreamController<Set<String>> _controllerFor(String userId) {
    return _controllers.putIfAbsent(userId, () => StreamController<Set<String>>.broadcast());
  }

  void _emit(String userId) {
    _controllerFor(userId).add(Set.unmodifiable(_favoritesByUser[userId] ?? {}));
  }

  @override
  Stream<Set<String>> watchFavorites(String userId) {
    final controller = _controllerFor(userId);
    Future.microtask(() => _emit(userId));
    return controller.stream;
  }

  @override
  Future<void> addFavorite(String userId, String placeId) async {
    final set = _favoritesByUser.putIfAbsent(userId, () => {});
    set.add(placeId);
    _emit(userId);
  }

  @override
  Future<void> removeFavorite(String userId, String placeId) async {
    _favoritesByUser[userId]?.remove(placeId);
    _emit(userId);
  }
}
