/// A single activity/stop within one day of an itinerary.
class ItineraryItem {
  final String time; // e.g. "09:00 AM"
  final String title;
  final String description;
  final String? placeId;
  final String icon; // maps to an icon key used by the UI

  const ItineraryItem({
    required this.time,
    required this.title,
    required this.description,
    this.placeId,
    this.icon = 'place',
  });

  Map<String, dynamic> toJson() => {
        'time': time,
        'title': title,
        'description': description,
        'placeId': placeId,
        'icon': icon,
      };

  factory ItineraryItem.fromJson(Map<String, dynamic> json) => ItineraryItem(
        time: json['time'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        placeId: json['placeId'] as String?,
        icon: json['icon'] as String? ?? 'place',
      );
}

/// One day of a generated trip itinerary.
class ItineraryDay {
  final int dayNumber;
  final String title;
  final List<ItineraryItem> items;

  const ItineraryDay({
    required this.dayNumber,
    required this.title,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'title': title,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory ItineraryDay.fromJson(Map<String, dynamic> json) => ItineraryDay(
        dayNumber: json['dayNumber'] as int,
        title: json['title'] as String,
        items: (json['items'] as List<dynamic>).map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// Breakdown of estimated costs for a planned trip, all values in BDT.
class BudgetEstimate {
  final double transport;
  final double hotel;
  final double food;
  final double shopping;
  final double activities;

  const BudgetEstimate({
    required this.transport,
    required this.hotel,
    required this.food,
    required this.shopping,
    required this.activities,
  });

  double get total => transport + hotel + food + shopping + activities;

  Map<String, double> get breakdown => {
        'Transport': transport,
        'Hotel': hotel,
        'Food': food,
        'Shopping': shopping,
        'Activities': activities,
      };

  Map<String, dynamic> toJson() => {
        'transport': transport,
        'hotel': hotel,
        'food': food,
        'shopping': shopping,
        'activities': activities,
      };

  factory BudgetEstimate.fromJson(Map<String, dynamic> json) => BudgetEstimate(
        transport: (json['transport'] as num).toDouble(),
        hotel: (json['hotel'] as num).toDouble(),
        food: (json['food'] as num).toDouble(),
        shopping: (json['shopping'] as num).toDouble(),
        activities: (json['activities'] as num).toDouble(),
      );
}

enum TransportMode { bus, train, flight, launch, privateCar }

enum TripStatus { draft, upcoming, completed }

/// A full trip plan: the destination, dates, preferences, generated
/// itinerary and budget estimate. This is what gets persisted (locally via
/// Hive, and to Firestore once signed in) so users can revisit their plans.
class TripPlan {
  final String id;
  final String destinationDistrictId;
  final String destinationName;
  final DateTime startDate;
  final DateTime endDate;
  final int travelers;
  final TransportMode transportMode;
  final String? hotelId;
  final double budgetCap;
  final List<ItineraryDay> itinerary;
  final BudgetEstimate estimate;
  final TripStatus status;
  final DateTime createdAt;

  const TripPlan({
    required this.id,
    required this.destinationDistrictId,
    required this.destinationName,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    required this.transportMode,
    required this.budgetCap,
    required this.itinerary,
    required this.estimate,
    this.hotelId,
    this.status = TripStatus.draft,
    required this.createdAt,
  });

  int get durationDays => endDate.difference(startDate).inDays + 1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'destinationDistrictId': destinationDistrictId,
        'destinationName': destinationName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'travelers': travelers,
        'transportMode': transportMode.name,
        'hotelId': hotelId,
        'budgetCap': budgetCap,
        'itinerary': itinerary.map((d) => d.toJson()).toList(),
        'estimate': estimate.toJson(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TripPlan.fromJson(Map<String, dynamic> json) => TripPlan(
        id: json['id'] as String,
        destinationDistrictId: json['destinationDistrictId'] as String,
        destinationName: json['destinationName'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        travelers: json['travelers'] as int,
        transportMode: TransportMode.values.firstWhere(
          (e) => e.name == json['transportMode'],
          orElse: () => TransportMode.bus,
        ),
        hotelId: json['hotelId'] as String?,
        budgetCap: (json['budgetCap'] as num).toDouble(),
        itinerary: (json['itinerary'] as List<dynamic>).map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>)).toList(),
        estimate: BudgetEstimate.fromJson(json['estimate'] as Map<String, dynamic>),
        status: TripStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TripStatus.draft,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
