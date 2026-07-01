/// Represents one of Bangladesh's 8 administrative divisions.
///
/// The travel guide hierarchy is: Division -> District -> TouristPlace.
/// Only [districtIds] are stored here (not full District objects) to keep
/// this model light; the repository resolves the relationship.
class Division {
  final String id;
  final String name;
  final String banglaName;
  final String description;
  final String imageUrl;
  final List<String> districtIds;

  const Division({
    required this.id,
    required this.name,
    required this.banglaName,
    required this.description,
    required this.imageUrl,
    required this.districtIds,
  });

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id'] as String,
      name: json['name'] as String,
      banglaName: json['banglaName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      districtIds: (json['districtIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'banglaName': banglaName,
        'description': description,
        'imageUrl': imageUrl,
        'districtIds': districtIds,
      };
}

/// Represents one of Bangladesh's 64 districts.
///
/// In this build only a handful of districts have rich data populated
/// (see [assets/data/districts.json]); the remaining districts exist as
/// lightweight stub entries so the Division -> District navigation works
/// for the full country, ready to be enriched later.
class District {
  final String id;
  final String divisionId;
  final String name;
  final String banglaName;
  final String description;
  final String imageUrl;
  final List<String> touristPlaceIds;
  final bool hasRichData;

  const District({
    required this.id,
    required this.divisionId,
    required this.name,
    required this.banglaName,
    required this.description,
    required this.imageUrl,
    required this.touristPlaceIds,
    this.hasRichData = false,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as String,
      divisionId: json['divisionId'] as String,
      name: json['name'] as String,
      banglaName: json['banglaName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      touristPlaceIds: (json['touristPlaceIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      hasRichData: json['hasRichData'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'divisionId': divisionId,
        'name': name,
        'banglaName': banglaName,
        'description': description,
        'imageUrl': imageUrl,
        'touristPlaceIds': touristPlaceIds,
        'hasRichData': hasRichData,
      };
}
