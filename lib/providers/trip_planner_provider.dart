import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../data/repositories/firestore_trip_repository.dart';
import '../data/repositories/mock_trip_repository.dart';
import '../domain/repositories/trip_repository.dart';
import '../models/trip_plan_model.dart';
import '../core/utils/admin_contact.dart';
import 'support_provider.dart';
import 'auth_provider.dart';

const _uuid = Uuid();

/// Holds the in-progress trip configuration as the user moves through the
/// Trip Planner wizard (destination -> dates -> budget -> travelers ->
/// transport -> hotel -> generated itinerary).
class TripDraft {
  final String? destinationDistrictId;
  final String? destinationName;
  final DateTime? startDate;
  final DateTime? endDate;
  final int travelers;
  final TransportMode transportMode;
  final String? hotelId;
  final double budgetCap;

  const TripDraft({
    this.destinationDistrictId,
    this.destinationName,
    this.startDate,
    this.endDate,
    this.travelers = 2,
    this.transportMode = TransportMode.bus,
    this.hotelId,
    this.budgetCap = 10000,
  });

  TripDraft copyWith({
    String? destinationDistrictId,
    String? destinationName,
    DateTime? startDate,
    DateTime? endDate,
    int? travelers,
    TransportMode? transportMode,
    String? hotelId,
    double? budgetCap,
  }) {
    return TripDraft(
      destinationDistrictId: destinationDistrictId ?? this.destinationDistrictId,
      destinationName: destinationName ?? this.destinationName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      travelers: travelers ?? this.travelers,
      transportMode: transportMode ?? this.transportMode,
      hotelId: hotelId ?? this.hotelId,
      budgetCap: budgetCap ?? this.budgetCap,
    );
  }

  int get durationDays {
    if (startDate == null || endDate == null) return 1;
    return endDate!.difference(startDate!).inDays + 1;
  }

  bool get isComplete => destinationDistrictId != null && startDate != null && endDate != null;
}

class TripDraftController extends StateNotifier<TripDraft> {
  TripDraftController() : super(const TripDraft());

  void setDestination(String districtId, String name) {
    state = state.copyWith(destinationDistrictId: districtId, destinationName: name);
  }

  void setDates(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void setTravelers(int count) {
    state = state.copyWith(travelers: count.clamp(1, 20));
  }

  void setTransportMode(TransportMode mode) {
    state = state.copyWith(transportMode: mode);
  }

  void setHotel(String hotelId) {
    state = state.copyWith(hotelId: hotelId);
  }

  void setBudgetCap(double value) {
    state = state.copyWith(budgetCap: value);
  }

  void reset() {
    state = const TripDraft();
  }
}

final tripDraftProvider = StateNotifierProvider<TripDraftController, TripDraft>((ref) {
  return TripDraftController();
});

/// Per-person, per-day cost assumptions (BDT) used by the budget
/// calculator. These are rough, editable placeholders — swap for live
/// pricing data once transport/hotel partner APIs are integrated.
class _CostAssumptions {
  static const Map<TransportMode, double> roundTripPerPerson = {
    TransportMode.bus: 1600,
    TransportMode.train: 1200,
    TransportMode.flight: 9000,
    TransportMode.launch: 1000,
    TransportMode.privateCar: 6000, // shared across the group, applied flat
  };

  static const double hotelPerNight = 3500; // mid-range room, shared by 2
  static const double foodPerPersonPerDay = 800;
  static const double shoppingPerPerson = 1000; // flat, one-off
  static const double activitiesPerPersonPerDay = 500;
}

/// Computes a [BudgetEstimate] for the given trip draft.
BudgetEstimate calculateBudget(TripDraft draft) {
  final days = draft.durationDays;
  final travelers = draft.travelers;

  final transportBase = _CostAssumptions.roundTripPerPerson[draft.transportMode] ?? 1500;
  final transport = draft.transportMode == TransportMode.privateCar
      ? transportBase // flat cost regardless of traveler count
      : transportBase * travelers;

  final rooms = (travelers / 2).ceil();
  final hotel = _CostAssumptions.hotelPerNight * rooms * days;

  final food = _CostAssumptions.foodPerPersonPerDay * travelers * days;
  final shopping = _CostAssumptions.shoppingPerPerson * travelers;
  final activities = _CostAssumptions.activitiesPerPersonPerDay * travelers * days;

  return BudgetEstimate(
    transport: transport,
    hotel: hotel,
    food: food,
    shopping: shopping,
    activities: activities,
  );
}

/// Generates a simple day-by-day itinerary skeleton for the destination.
/// This is intentionally template-based (morning sightseeing, afternoon
/// exploration, evening relaxation) rather than place-specific, since full
/// per-destination itinerary data isn't populated for every district yet.
List<ItineraryDay> generateItinerary(TripDraft draft) {
  final days = draft.durationDays;
  final destination = draft.destinationName ?? 'your destination';

  return List.generate(days, (index) {
    final dayNum = index + 1;
    if (dayNum == 1) {
      return ItineraryDay(
        dayNumber: dayNum,
        title: 'Arrival & First Look',
        items: [
          const ItineraryItem(time: '09:00 AM', title: 'Depart for destination', description: 'Travel by your selected transport mode.', icon: 'directions_bus'),
          ItineraryItem(time: '02:00 PM', title: 'Check in to hotel', description: 'Settle in and freshen up at your stay in $destination.', icon: 'hotel'),
          const ItineraryItem(time: '05:00 PM', title: 'Evening orientation walk', description: 'Explore the main area on foot and scout dinner spots.', icon: 'directions_walk'),
        ],
      );
    } else if (dayNum == days && days > 1) {
      return ItineraryDay(
        dayNumber: dayNum,
        title: 'Last Sights & Departure',
        items: [
          const ItineraryItem(time: '08:00 AM', title: 'Final sightseeing', description: 'Visit any remaining must-see spots before checkout.', icon: 'photo_camera'),
          const ItineraryItem(time: '12:00 PM', title: 'Check out & lunch', description: 'Grab a final local meal before heading back.', icon: 'restaurant'),
          const ItineraryItem(time: '02:00 PM', title: 'Return journey', description: 'Head back home via your chosen transport.', icon: 'directions_bus'),
        ],
      );
    } else {
      return ItineraryDay(
        dayNumber: dayNum,
        title: 'Full Day Exploration',
        items: [
          const ItineraryItem(time: '08:00 AM', title: 'Breakfast', description: 'Start the day with a local breakfast near your hotel.', icon: 'restaurant'),
          ItineraryItem(time: '09:30 AM', title: 'Visit top attractions', description: 'Explore the main tourist spots around $destination.', icon: 'place'),
          const ItineraryItem(time: '01:00 PM', title: 'Lunch break', description: 'Try regional specialties at a local restaurant.', icon: 'restaurant'),
          const ItineraryItem(time: '03:00 PM', title: 'Leisure / optional activity', description: 'Relax, shop, or add an optional activity (boat ride, trek, etc).', icon: 'hiking'),
          const ItineraryItem(time: '07:00 PM', title: 'Dinner & evening relaxation', description: 'Wind down with dinner and a stroll.', icon: 'nightlife'),
        ],
      );
    }
  });
}

/// Combines [calculateBudget] + [generateItinerary] into a saved [TripPlan].
TripPlan buildTripPlan(TripDraft draft) {
  return TripPlan(
    id: _uuid.v4(),
    destinationDistrictId: draft.destinationDistrictId ?? '',
    destinationName: draft.destinationName ?? 'Unknown',
    startDate: draft.startDate ?? DateTime.now(),
    endDate: draft.endDate ?? DateTime.now(),
    travelers: draft.travelers,
    transportMode: draft.transportMode,
    hotelId: draft.hotelId,
    budgetCap: draft.budgetCap,
    itinerary: generateItinerary(draft),
    estimate: calculateBudget(draft),
    status: TripStatus.upcoming,
    createdAt: DateTime.now(),
  );
}

/// Provides the active [TripRepository] implementation. Controlled by
/// [AppConfig.useFirebase], same pattern as auth/favorites/storage.
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirestoreTripRepository();
  }
  return MockTripRepository();
});

/// Streams the signed-in (or guest) user's saved trips.
final savedTripsStreamProvider = StreamProvider<List<TripPlan>>((ref) {
  final user = ref.watch(currentUserProvider);
  final repo = ref.watch(tripRepositoryProvider);
  if (user == null) return Stream.value(<TripPlan>[]);
  return repo.watchTrips(user.uid);
});

/// Convenience provider exposing saved trips as a plain list (never
/// loading/error states) for widgets that don't want AsyncValue handling.
final savedTripsProvider = Provider<List<TripPlan>>((ref) {
  return ref.watch(savedTripsStreamProvider).maybeWhen(data: (t) => t, orElse: () => <TripPlan>[]);
});

/// Saves a generated [TripPlan] for the current user. Function-style
/// provider (not a StateNotifier) since the actual list lives in
/// [savedTripsStreamProvider] / the repository.
final saveTripProvider = Provider<Future<void> Function(TripPlan)>((ref) {
  return (TripPlan trip) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(tripRepositoryProvider);
    await repo.saveTrip(user.uid, trip);
    // Create an initial support ticket message so admins see new trip plans
    // and users can immediately chat about the trip. This uses the same
    // addUserMessage action so behavior matches manual messaging.
    try {
      final welcome = buildSupportChatWelcomeMessage(destinationName: trip.destinationName, tripId: trip.id);
      await ref.read(supportActionsProvider).addUserMessage(
        destinationName: trip.destinationName,
        tripId: trip.id,
        message: welcome,
          );
    } catch (e) {
      // Don't fail the save if support message fails; log for debugging.
      // Firestore rules may reject this if auth/profile isn't synced yet.
      // We intentionally swallow errors to keep UX smooth.
    }
  };
});

final deleteTripProvider = Provider<Future<void> Function(String)>((ref) {
  return (String tripId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(tripRepositoryProvider);
    await repo.deleteTrip(user.uid, tripId);
  };
});
