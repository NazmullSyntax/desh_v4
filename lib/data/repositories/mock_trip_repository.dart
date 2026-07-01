import 'dart:async';
import '../../domain/repositories/trip_repository.dart';
import '../../models/trip_plan_model.dart';

/// In-memory mock implementation of [TripRepository], used until Firebase
/// is configured (see [FirestoreTripRepository] for the real backend).
/// Keeps trips per-userId so guest vs signed-in users don't bleed into
/// each other's data, same as the real Firestore layout would.
class MockTripRepository implements TripRepository {
  final Map<String, List<TripPlan>> _tripsByUser = {};
  final Map<String, StreamController<List<TripPlan>>> _controllers = {};

  StreamController<List<TripPlan>> _controllerFor(String userId) {
    return _controllers.putIfAbsent(userId, () => StreamController<List<TripPlan>>.broadcast());
  }

  void _emit(String userId) {
    _controllerFor(userId).add(List.unmodifiable(_tripsByUser[userId] ?? []));
  }

  @override
  Stream<List<TripPlan>> watchTrips(String userId) {
    final controller = _controllerFor(userId);
    // Emit current state to the new listener right away.
    Future.microtask(() => _emit(userId));
    return controller.stream;
  }

  @override
  Future<void> saveTrip(String userId, TripPlan trip) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final list = _tripsByUser.putIfAbsent(userId, () => []);
    list.removeWhere((t) => t.id == trip.id);
    list.insert(0, trip);
    _emit(userId);
  }

  @override
  Future<void> deleteTrip(String userId, String tripId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _tripsByUser[userId]?.removeWhere((t) => t.id == tripId);
    _emit(userId);
  }
}
