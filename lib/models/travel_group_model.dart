/// A lightweight, denormalized profile snapshot for a group member —
/// enough to render an avatar stack and a name without a second lookup.
/// Real member documents (once Firestore is wired) simply carry this same
/// shape under `members/{uid}` inside the group.
class GroupMemberProfile {
  final String uid;
  final String name;
  final String? photoUrl;

  const GroupMemberProfile({required this.uid, required this.name, this.photoUrl});

  factory GroupMemberProfile.fromJson(Map<String, dynamic> json) => GroupMemberProfile(
        uid: json['uid'] as String,
        name: json['name'] as String? ?? 'Traveler',
        photoUrl: json['photoUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {'uid': uid, 'name': name, 'photoUrl': photoUrl};
}

/// A traveler-created group trip to a specific destination — the core of
/// the Travel Group System / Solo Traveler Community features.
class TravelGroup {
  final String id;
  final String placeId;
  final String destinationName;
  final String coverImage;
  final String title;
  final DateTime tripDate;
  final String meetingPoint;
  final double budgetBdt;
  final int maxMembers;
  final String description;
  final String createdByUid;
  final DateTime createdAt;

  /// Members already confirmed in the group (creator is always first).
  final List<GroupMemberProfile> members;

  /// Users who tapped "Request to Join" and are awaiting the creator's
  /// approval — only used when [isRequestApprovalRequired] is true.
  final List<GroupMemberProfile> pendingRequests;

  /// If true, joining requires the creator's approval (Request Join /
  /// Approve / Reject flow). If false, anyone can tap Join directly as
  /// long as there's a free seat.
  final bool isRequestApprovalRequired;

  const TravelGroup({
    required this.id,
    required this.placeId,
    required this.destinationName,
    required this.coverImage,
    required this.title,
    required this.tripDate,
    required this.meetingPoint,
    required this.budgetBdt,
    required this.maxMembers,
    required this.description,
    required this.createdByUid,
    required this.createdAt,
    required this.members,
    this.pendingRequests = const [],
    this.isRequestApprovalRequired = false,
  });

  int get remainingSeats => (maxMembers - members.length).clamp(0, maxMembers);
  bool get isFull => remainingSeats <= 0;
  bool isMember(String uid) => members.any((m) => m.uid == uid);
  bool hasPendingRequest(String uid) => pendingRequests.any((m) => m.uid == uid);
  bool isOwner(String uid) => createdByUid == uid;

  TravelGroup copyWith({
    List<GroupMemberProfile>? members,
    List<GroupMemberProfile>? pendingRequests,
  }) {
    return TravelGroup(
      id: id,
      placeId: placeId,
      destinationName: destinationName,
      coverImage: coverImage,
      title: title,
      tripDate: tripDate,
      meetingPoint: meetingPoint,
      budgetBdt: budgetBdt,
      maxMembers: maxMembers,
      description: description,
      createdByUid: createdByUid,
      createdAt: createdAt,
      members: members ?? this.members,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      isRequestApprovalRequired: isRequestApprovalRequired,
    );
  }

  factory TravelGroup.fromJson(Map<String, dynamic> json) => TravelGroup(
        id: json['id'] as String,
        placeId: json['placeId'] as String,
        destinationName: json['destinationName'] as String,
        coverImage: json['coverImage'] as String? ?? '',
        title: json['title'] as String,
        tripDate: DateTime.parse(json['tripDate'] as String),
        meetingPoint: json['meetingPoint'] as String,
        budgetBdt: (json['budgetBdt'] as num).toDouble(),
        maxMembers: json['maxMembers'] as int,
        description: json['description'] as String? ?? '',
        createdByUid: json['createdByUid'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        members: (json['members'] as List<dynamic>? ?? [])
            .map((e) => GroupMemberProfile.fromJson(e as Map<String, dynamic>))
            .toList(),
        pendingRequests: (json['pendingRequests'] as List<dynamic>? ?? [])
            .map((e) => GroupMemberProfile.fromJson(e as Map<String, dynamic>))
            .toList(),
        isRequestApprovalRequired: json['isRequestApprovalRequired'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'placeId': placeId,
        'destinationName': destinationName,
        'coverImage': coverImage,
        'title': title,
        'tripDate': tripDate.toIso8601String(),
        'meetingPoint': meetingPoint,
        'budgetBdt': budgetBdt,
        'maxMembers': maxMembers,
        'description': description,
        'createdByUid': createdByUid,
        'createdAt': createdAt.toIso8601String(),
        'members': members.map((m) => m.toJson()).toList(),
        'pendingRequests': pendingRequests.map((m) => m.toJson()).toList(),
        'isRequestApprovalRequired': isRequestApprovalRequired,
      };
}

/// A single chat message inside a group's trip-planning thread.
class GroupChatMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final String text;
  final DateTime timestamp;

  const GroupChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });
}
