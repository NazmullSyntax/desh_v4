import '../../models/travel_group_model.dart';

/// Domain-layer contract for the Travel Group System. Presentation code
/// only ever talks to this interface — never to Firestore or the mock
/// store directly — same pattern as [AuthRepository] / [FavoritesRepository].
abstract class GroupsRepository {
  /// All open groups heading to a given destination (place), newest first.
  Stream<List<TravelGroup>> watchGroupsForPlace(String placeId);

  /// Every group the given user is a member of, is the creator of, or has
  /// a pending join request on — used for the "My Groups" screen.
  Stream<List<TravelGroup>> watchMyGroups(String uid);

  Stream<TravelGroup?> watchGroup(String groupId);

  Future<TravelGroup> createGroup({
    required String placeId,
    required String destinationName,
    required String coverImage,
    required String title,
    required DateTime tripDate,
    required String meetingPoint,
    required double budgetBdt,
    required int maxMembers,
    required String description,
    required bool requireApproval,
    required GroupMemberProfile creator,
  });

  /// Joins immediately — only valid when the group doesn't require approval.
  Future<void> joinGroup(String groupId, GroupMemberProfile member);

  /// Sends a join request that the creator must approve.
  Future<void> requestJoin(String groupId, GroupMemberProfile member);

  Future<void> approveRequest(String groupId, String uid);

  Future<void> rejectRequest(String groupId, String uid);

  Future<void> leaveGroup(String groupId, String uid);

  // ---- Lightweight in-group chat (mock/local for now; swap for the
  // real-time chat backend once item #7, Real-Time Chat, is built) ----
  Stream<List<GroupChatMessage>> watchGroupChat(String groupId);

  Future<void> sendGroupChatMessage(String groupId, GroupChatMessage message);
}
