import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../data/repositories/firestore_groups_repository.dart';
import '../data/repositories/mock_groups_repository.dart';
import '../domain/repositories/groups_repository.dart';
import '../models/travel_group_model.dart';
import 'auth_provider.dart';

const _uuid = Uuid();

/// Provides the active [GroupsRepository] implementation, controlled by
/// [AppConfig.useFirebase] — same switch used by every other feature.
final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirestoreGroupsRepository();
  }
  return MockGroupsRepository();
});

/// Groups heading to a specific destination — powers the "Travelers
/// Planning This Trip" section on the place detail screen and the
/// "Browse groups for this destination" list.
final groupsForPlaceProvider = StreamProvider.family<List<TravelGroup>, String>((ref, placeId) {
  return ref.watch(groupsRepositoryProvider).watchGroupsForPlace(placeId);
});

/// The signed-in user's own groups (owned, joined, or pending approval).
final myGroupsProvider = StreamProvider<List<TravelGroup>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(groupsRepositoryProvider).watchMyGroups(user.uid);
});

final groupByIdProvider = StreamProvider.family<TravelGroup?, String>((ref, groupId) {
  return ref.watch(groupsRepositoryProvider).watchGroup(groupId);
});

final groupChatProvider = StreamProvider.family<List<GroupChatMessage>, String>((ref, groupId) {
  return ref.watch(groupsRepositoryProvider).watchGroupChat(groupId);
});

/// Builds a [GroupMemberProfile] for the signed-in user, falling back to a
/// display name derived from email/guest state (mirrors [AppUser.displayName]).
GroupMemberProfile _profileForCurrentUser(Ref ref) {
  final user = ref.read(currentUserProvider);
  return GroupMemberProfile(uid: user!.uid, name: user.displayName, photoUrl: user.photoUrl);
}

/// Action surface for the Travel Group System — create/join/leave/approve.
/// Kept as plain async functions (not a StateNotifier) since state lives in
/// the repository streams above; this just issues the mutating calls.
class GroupsActions {
  final Ref _ref;
  GroupsActions(this._ref);

  Future<TravelGroup?> createGroup({
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
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return null;
    return _ref.read(groupsRepositoryProvider).createGroup(
          placeId: placeId,
          destinationName: destinationName,
          coverImage: coverImage,
          title: title,
          tripDate: tripDate,
          meetingPoint: meetingPoint,
          budgetBdt: budgetBdt,
          maxMembers: maxMembers,
          description: description,
          requireApproval: requireApproval,
          creator: _profileForCurrentUser(_ref),
        );
  }

  Future<void> joinOrRequest(TravelGroup group) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    final repo = _ref.read(groupsRepositoryProvider);
    final profile = _profileForCurrentUser(_ref);
    if (group.isRequestApprovalRequired) {
      await repo.requestJoin(group.id, profile);
    } else {
      await repo.joinGroup(group.id, profile);
    }
  }

  Future<void> leaveGroup(String groupId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    await _ref.read(groupsRepositoryProvider).leaveGroup(groupId, user.uid);
  }

  Future<void> approveRequest(String groupId, String uid) {
    return _ref.read(groupsRepositoryProvider).approveRequest(groupId, uid);
  }

  Future<void> rejectRequest(String groupId, String uid) {
    return _ref.read(groupsRepositoryProvider).rejectRequest(groupId, uid);
  }

  Future<void> sendChatMessage(String groupId, String text) async {
    final user = _ref.read(currentUserProvider);
    if (user == null || text.trim().isEmpty) return;
    await _ref.read(groupsRepositoryProvider).sendGroupChatMessage(
          groupId,
          GroupChatMessage(
            id: _uuid.v4(),
            senderUid: user.uid,
            senderName: user.displayName,
            text: text.trim(),
            timestamp: DateTime.now(),
          ),
        );
  }
}

final groupsActionsProvider = Provider<GroupsActions>((ref) => GroupsActions(ref));
