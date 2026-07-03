import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/firebase_constants.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../models/trip_plan_model.dart';

/// Firestore implementation of [TripRepository].
///
/// Data layout: `users/{userId}/trips/{tripId}` — one document per trip,
/// scoped under the user so Firestore security rules can simply check
/// `request.auth.uid == userId` (see the example rules in
/// SETUP_INSTRUCTIONS.md).
class FirestoreTripRepository implements TripRepository {
  final FirebaseFirestore _firestore;

  FirestoreTripRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tripsCollection(String userId) {
    return _firestore.collection(FirebaseConstants.userCollection).doc(userId).collection('trips');
  }

  @override
  Stream<List<TripPlan>> watchTrips(String userId) {
    return _tripsCollection(userId).orderBy(FirebaseConstants.fieldCreatedAt, descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => TripPlan.fromJson(doc.data())).toList(),
        );
  }

  @override
  Future<void> saveTrip(String userId, TripPlan trip) async {
    await _tripsCollection(userId).doc(trip.id).set(trip.toJson());
  }

  @override
  Future<void> deleteTrip(String userId, String tripId) async {
    await _tripsCollection(userId).doc(tripId).delete();
  }
}
