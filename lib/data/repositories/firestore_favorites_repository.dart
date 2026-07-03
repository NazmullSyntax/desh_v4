import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/firebase_constants.dart';
import '../../domain/repositories/favorites_repository.dart';

/// Firestore implementation of [FavoritesRepository].
///
/// Data layout: `users/{userId}/favorites/{placeId}` — one tiny document
/// per favorited place (just a marker `{addedAt: ...}`), rather than a
/// single array field, so concurrent add/remove from multiple devices
/// can't silently clobber each other the way array updates sometimes do.
class FirestoreFavoritesRepository implements FavoritesRepository {
  final FirebaseFirestore _firestore;

  FirestoreFavoritesRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _favoritesCollection(String userId) {
    return _firestore.collection(FirebaseConstants.userCollection).doc(userId).collection('favorites');
  }

  @override
  Stream<Set<String>> watchFavorites(String userId) {
    return _favoritesCollection(userId).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.id).toSet(),
        );
  }

  @override
  Future<void> addFavorite(String userId, String placeId) async {
    await _favoritesCollection(userId).doc(placeId).set({'addedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> removeFavorite(String userId, String placeId) async {
    await _favoritesCollection(userId).doc(placeId).delete();
  }
}
