/// A single review left by a user on a [TouristPlace].
class PlaceReview {
  final String id;
  final String userName;
  final String userAvatarUrl;
  final double rating; // 0.0 - 5.0
  final String comment;
  final DateTime createdAt;

  const PlaceReview({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory PlaceReview.fromJson(Map<String, dynamic> json) {
    return PlaceReview(
      id: json['id'] as String,
      userName: json['userName'] as String,
      userAvatarUrl: json['userAvatarUrl'] as String? ?? '',
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userName': userName,
        'userAvatarUrl': userAvatarUrl,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// A lightweight reference to a nearby hotel/restaurant/attraction shown on
/// a tourist place's detail screen. Kept separate from the full [Hotel]
/// model so the guide doesn't need to eagerly load entire hotel records.
class NearbyRef {
  final String id;
  final String name;
  final String imageUrl;
  final double distanceKm;
  final double? rating;

  const NearbyRef({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.distanceKm,
    this.rating,
  });

  factory NearbyRef.fromJson(Map<String, dynamic> json) {
    return NearbyRef(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}

/// Emergency contact entry tied to a specific tourist place / district
/// (local police, hospital, tourist police, etc).
class EmergencyContact {
  final String label;
  final String phoneNumber;

  const EmergencyContact({required this.label, required this.phoneNumber});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      label: json['label'] as String,
      phoneNumber: json['phoneNumber'] as String,
    );
  }
}

/// The core entity of the Travel Guide module: a single tourist destination
/// (beach, hill station, heritage site, etc) with everything needed to
/// render a rich detail screen.
class TouristPlace {
  final String id;
  final String districtId;
  final String name;
  final String banglaName;
  final List<String> imageUrls;
  final String shortDescription;
  final String description;
  final String history;
  final String bestTimeToVisit;
  final String entryFee;
  final String openingHours;
  final List<String> travelTips;
  final double distanceFromDhakaKm;
  final double latitude;
  final double longitude;
  final List<NearbyRef> nearbyHotels;
  final List<NearbyRef> nearbyRestaurants;
  final List<NearbyRef> nearbyAttractions;
  final List<EmergencyContact> emergencyContacts;
  final List<PlaceReview> reviews;
  final double averageRating;
  final List<String> category; // e.g. beach, hill, heritage, wildlife
  final bool isTrending;
  final bool isPopular;

  const TouristPlace({
    required this.id,
    required this.districtId,
    required this.name,
    required this.banglaName,
    required this.imageUrls,
    required this.shortDescription,
    required this.description,
    required this.history,
    required this.bestTimeToVisit,
    required this.entryFee,
    required this.openingHours,
    required this.travelTips,
    required this.distanceFromDhakaKm,
    required this.latitude,
    required this.longitude,
    this.nearbyHotels = const [],
    this.nearbyRestaurants = const [],
    this.nearbyAttractions = const [],
    this.emergencyContacts = const [],
    this.reviews = const [],
    this.averageRating = 0,
    this.category = const [],
    this.isTrending = false,
    this.isPopular = false,
  });

  String get coverImage => imageUrls.isNotEmpty ? imageUrls.first : '';

  factory TouristPlace.fromJson(Map<String, dynamic> json) {
    return TouristPlace(
      id: json['id'] as String,
      districtId: json['districtId'] as String,
      name: json['name'] as String,
      banglaName: json['banglaName'] as String? ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      shortDescription: json['shortDescription'] as String? ?? '',
      description: json['description'] as String? ?? '',
      history: json['history'] as String? ?? '',
      bestTimeToVisit: json['bestTimeToVisit'] as String? ?? '',
      entryFee: json['entryFee'] as String? ?? '',
      openingHours: json['openingHours'] as String? ?? '',
      travelTips: (json['travelTips'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      distanceFromDhakaKm: (json['distanceFromDhakaKm'] as num?)?.toDouble() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      nearbyHotels: (json['nearbyHotels'] as List<dynamic>? ?? [])
          .map((e) => NearbyRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      nearbyRestaurants: (json['nearbyRestaurants'] as List<dynamic>? ?? [])
          .map((e) => NearbyRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      nearbyAttractions: (json['nearbyAttractions'] as List<dynamic>? ?? [])
          .map((e) => NearbyRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      emergencyContacts: (json['emergencyContacts'] as List<dynamic>? ?? [])
          .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map((e) => PlaceReview.fromJson(e as Map<String, dynamic>))
          .toList(),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      category: (json['category'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      isTrending: json['isTrending'] as bool? ?? false,
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'districtId': districtId,
        'name': name,
        'banglaName': banglaName,
        'imageUrls': imageUrls,
        'shortDescription': shortDescription,
        'description': description,
        'history': history,
        'bestTimeToVisit': bestTimeToVisit,
        'entryFee': entryFee,
        'openingHours': openingHours,
        'travelTips': travelTips,
        'distanceFromDhakaKm': distanceFromDhakaKm,
        'latitude': latitude,
        'longitude': longitude,
        'averageRating': averageRating,
        'category': category,
        'isTrending': isTrending,
        'isPopular': isPopular,
      };
}
