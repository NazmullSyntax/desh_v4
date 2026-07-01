import '../../models/trip_plan_model.dart';

/// Domain-layer contract for persisting [TripPlan]s. Mirrors the
/// [AuthRepository] pattern — screens and the trip-planner providers
/// only ever talk to this interface, never to Firestore directly.
abstract class TripRepository {
  /// Streams the signed-in user's saved trips, ordered newest first.
  Stream<List<TripPlan>> watchTrips(String userId);

  Future<void> saveTrip(String userId, TripPlan trip);

  Future<void> deleteTrip(String userId, String tripId);
}
