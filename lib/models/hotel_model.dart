enum AccommodationType { hotel, resort, guestHouse }

class Hotel {
  final String id;
  final String name;
  final AccommodationType type;
  final List<String> imageUrls;
  final double rating;
  final int reviewCount;
  final double pricePerNight; // in BDT
  final String districtId;
  final String address;
  final List<String> facilities;
  final String contactPhone;
  final double latitude;
  final double longitude;
  final bool isBookable;

  const Hotel({
    required this.id,
    required this.name,
    required this.type,
    required this.imageUrls,
    required this.rating,
    required this.reviewCount,
    required this.pricePerNight,
    required this.districtId,
    required this.address,
    required this.facilities,
    required this.contactPhone,
    required this.latitude,
    required this.longitude,
    this.isBookable = false,
  });

  String get coverImage => imageUrls.isNotEmpty ? imageUrls.first : '';

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AccommodationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AccommodationType.hotel,
      ),
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ?? 0,
      districtId: json['districtId'] as String,
      address: json['address'] as String? ?? '',
      facilities: (json['facilities'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      contactPhone: json['contactPhone'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      isBookable: json['isBookable'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'imageUrls': imageUrls,
        'rating': rating,
        'reviewCount': reviewCount,
        'pricePerNight': pricePerNight,
        'districtId': districtId,
        'address': address,
        'facilities': facilities,
        'contactPhone': contactPhone,
        'latitude': latitude,
        'longitude': longitude,
        'isBookable': isBookable,
      };
}
