/// Represents the signed-in user. Deliberately decoupled from
/// `firebase_auth`'s `User` type so the rest of the app never depends on
/// Firebase directly — only [AuthRepository] talks to Firebase, and maps
/// its results onto this model.
class AppUser {
  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;
  final bool isGuest;
  final bool isEmailVerified;
  final DateTime? createdAt;

  // Lightweight travel stats shown on the Profile screen.
  final int placesVisited;
  final int tripsPlanned;
  final int reviewsWritten;
  final List<String> badgeIds;

  const AppUser({
    required this.uid,
    this.name,
    this.email,
    this.photoUrl,
    this.isGuest = false,
    this.isEmailVerified = false,
    this.createdAt,
    this.placesVisited = 0,
    this.tripsPlanned = 0,
    this.reviewsWritten = 0,
    this.badgeIds = const [],
  });

  String get displayName {
    if (isGuest) return 'Guest Explorer';
    if (name != null && name!.trim().isNotEmpty) return name!;
    return email?.split('@').first ?? 'Traveler';
  }

  factory AppUser.guest() => const AppUser(uid: 'guest', isGuest: true);

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isGuest: json['isGuest'] as bool? ?? false,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      placesVisited: json['placesVisited'] as int? ?? 0,
      tripsPlanned: json['tripsPlanned'] as int? ?? 0,
      reviewsWritten: json['reviewsWritten'] as int? ?? 0,
      badgeIds: (json['badgeIds'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'isGuest': isGuest,
        'isEmailVerified': isEmailVerified,
        'createdAt': createdAt?.toIso8601String(),
        'placesVisited': placesVisited,
        'tripsPlanned': tripsPlanned,
        'reviewsWritten': reviewsWritten,
        'badgeIds': badgeIds,
      };

  AppUser copyWith({
    String? name,
    String? email,
    String? photoUrl,
    bool? isEmailVerified,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isGuest: isGuest,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt,
      placesVisited: placesVisited,
      tripsPlanned: tripsPlanned,
      reviewsWritten: reviewsWritten,
      badgeIds: badgeIds,
    );
  }
}
