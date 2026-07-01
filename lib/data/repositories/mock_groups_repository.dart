import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/groups_repository.dart';
import '../../models/travel_group_model.dart';

const _uuid = Uuid();

/// In-memory mock implementation of [GroupsRepository], used until
/// Firebase is configured (see [AppConfig.useFirebase]). Seeded with a
/// handful of realistic groups so "Travelers Planning This Trip" has
/// something to show on first launch instead of an empty state.
class MockGroupsRepository implements GroupsRepository {
  final Map<String, TravelGroup> _groups = {};
  final Map<String, List<GroupChatMessage>> _chat = {};
  final _groupsController = StreamController<List<TravelGroup>>.broadcast();
  final Map<String, StreamController<List<GroupChatMessage>>> _chatControllers = {};

  MockGroupsRepository() {
    _seed();
  }

  void _emitGroups() {
    _groupsController.add(_groups.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    Future.microtask(() {}); // keep async semantics obvious at call sites
  }

  StreamController<List<GroupChatMessage>> _chatControllerFor(String groupId) {
    return _chatControllers.putIfAbsent(groupId, () => StreamController<List<GroupChatMessage>>.broadcast());
  }

  void _emitChat(String groupId) {
    _chatControllerFor(groupId).add(List.unmodifiable(_chat[groupId] ?? const []));
  }

  void _seed() {
    final now = DateTime.now();

    _groups['g1'] = TravelGroup(
      id: 'g1',
      placeId: 'sajek_valley',
      destinationName: "Sajek Valley",
      coverImage: 'assets/images/destinations/sajek_valley.png',
      title: 'Sea-of-clouds sunrise trip',
      tripDate: now.add(const Duration(days: 18)),
      meetingPoint: 'Dhaka (Saydabad bus stand)',
      budgetBdt: 5000,
      maxMembers: 8,
      description:
          'Overnight bus to Khagrachhari, catching the 10:30 AM army convoy up. Staying 1 night in a cottage near Konglak Para for sunrise views. Splitting jeep + resort costs evenly.',
      createdByUid: 'mock_rafi',
      createdAt: now.subtract(const Duration(days: 3)),
      isRequestApprovalRequired: true,
      members: const [
        GroupMemberProfile(uid: 'mock_rafi', name: 'Rafi Ahmed'),
        GroupMemberProfile(uid: 'mock_nusrat', name: 'Nusrat Jahan'),
        GroupMemberProfile(uid: 'mock_tanvir', name: 'Tanvir Hasan'),
        GroupMemberProfile(uid: 'mock_mim', name: 'Mim Akter'),
        GroupMemberProfile(uid: 'mock_shuvo', name: 'Shuvo Das'),
        GroupMemberProfile(uid: 'mock_farhana', name: 'Farhana Islam'),
      ],
    );

    _groups['g2'] = TravelGroup(
      id: 'g2',
      placeId: 'coxsbazar_beach',
      destinationName: "Cox's Bazar Beach",
      coverImage: 'assets/images/destinations/coxsbazar_beach.png',
      title: 'Long weekend beach trip',
      tripDate: now.add(const Duration(days: 9)),
      meetingPoint: "Dhaka Airport / Cox's Bazar Airport",
      budgetBdt: 6500,
      maxMembers: 6,
      description: 'Flying in Friday morning, back Sunday night. Marine Drive sunset + Himchari on Saturday. Budget hotel, split 4 ways per room.',
      createdByUid: 'mock_nusrat',
      createdAt: now.subtract(const Duration(days: 1)),
      members: const [
        GroupMemberProfile(uid: 'mock_nusrat', name: 'Nusrat Jahan'),
        GroupMemberProfile(uid: 'mock_arif', name: 'Arif Chowdhury'),
        GroupMemberProfile(uid: 'mock_priya', name: 'Priya Sarkar'),
      ],
    );

    _groups['g3'] = TravelGroup(
      id: 'g3',
      placeId: 'nilgiri_hills',
      destinationName: 'Nilgiri Hills, Bandarban',
      coverImage: 'assets/images/destinations/nilgiri_hills.png',
      title: 'Bandarban hill-tracts trek',
      tripDate: now.add(const Duration(days: 25)),
      meetingPoint: 'Chittagong bus terminal',
      budgetBdt: 4200,
      maxMembers: 5,
      description: 'Two-day trip covering Nilgiri, Chimbuk, and Nafakhum waterfall. Chander gari rental split between the group.',
      createdByUid: 'mock_tanvir',
      createdAt: now.subtract(const Duration(hours: 14)),
      members: const [
        GroupMemberProfile(uid: 'mock_tanvir', name: 'Tanvir Hasan'),
        GroupMemberProfile(uid: 'mock_mim', name: 'Mim Akter'),
      ],
    );

    for (final g in _groups.values) {
      _chat[g.id] = [
        GroupChatMessage(
          id: _uuid.v4(),
          senderUid: 'system',
          senderName: 'DeshExplorer',
          text: 'Group created for "${g.title}". Say hello to your fellow travelers!',
          timestamp: g.createdAt,
        ),
      ];
    }
  }

  @override
  Stream<List<TravelGroup>> watchGroupsForPlace(String placeId) {
    Future.microtask(_emitGroups);
    return _groupsController.stream.map(
      (groups) => groups.where((g) => g.placeId == placeId).toList(),
    );
  }

  @override
  Stream<List<TravelGroup>> watchMyGroups(String uid) {
    Future.microtask(_emitGroups);
    return _groupsController.stream.map(
      (groups) => groups.where((g) => g.isMember(uid) || g.hasPendingRequest(uid)).toList(),
    );
  }

  @override
  Stream<TravelGroup?> watchGroup(String groupId) {
    Future.microtask(_emitGroups);
    return _groupsController.stream.map(
      (groups) => groups.where((g) => g.id == groupId).cast<TravelGroup?>().firstOrNull,
    );
  }

  @override
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
  }) async {
    final group = TravelGroup(
      id: _uuid.v4(),
      placeId: placeId,
      destinationName: destinationName,
      coverImage: coverImage,
      title: title,
      tripDate: tripDate,
      meetingPoint: meetingPoint,
      budgetBdt: budgetBdt,
      maxMembers: maxMembers,
      description: description,
      createdByUid: creator.uid,
      createdAt: DateTime.now(),
      isRequestApprovalRequired: requireApproval,
      members: [creator],
    );
    _groups[group.id] = group;
    _chat[group.id] = [
      GroupChatMessage(
        id: _uuid.v4(),
        senderUid: 'system',
        senderName: 'DeshExplorer',
        text: 'Group created for "${group.title}". Invite friends or wait for join requests!',
        timestamp: group.createdAt,
      ),
    ];
    _emitGroups();
    return group;
  }

  @override
  Future<void> joinGroup(String groupId, GroupMemberProfile member) async {
    final g = _groups[groupId];
    if (g == null || g.isFull || g.isMember(member.uid)) return;
    _groups[groupId] = g.copyWith(members: [...g.members, member]);
    _emitGroups();
  }

  @override
  Future<void> requestJoin(String groupId, GroupMemberProfile member) async {
    final g = _groups[groupId];
    if (g == null || g.isFull || g.isMember(member.uid) || g.hasPendingRequest(member.uid)) return;
    _groups[groupId] = g.copyWith(pendingRequests: [...g.pendingRequests, member]);
    _emitGroups();
  }

  @override
  Future<void> approveRequest(String groupId, String uid) async {
    final g = _groups[groupId];
    if (g == null) return;
    final requester = g.pendingRequests.where((m) => m.uid == uid).cast<GroupMemberProfile?>().firstOrNull;
    if (requester == null || g.isFull) return;
    _groups[groupId] = g.copyWith(
      members: [...g.members, requester],
      pendingRequests: g.pendingRequests.where((m) => m.uid != uid).toList(),
    );
    _emitGroups();
  }

  @override
  Future<void> rejectRequest(String groupId, String uid) async {
    final g = _groups[groupId];
    if (g == null) return;
    _groups[groupId] = g.copyWith(pendingRequests: g.pendingRequests.where((m) => m.uid != uid).toList());
    _emitGroups();
  }

  @override
  Future<void> leaveGroup(String groupId, String uid) async {
    final g = _groups[groupId];
    if (g == null) return;
    _groups[groupId] = g.copyWith(members: g.members.where((m) => m.uid != uid).toList());
    _emitGroups();
  }

  @override
  Stream<List<GroupChatMessage>> watchGroupChat(String groupId) {
    Future.microtask(() => _emitChat(groupId));
    return _chatControllerFor(groupId).stream;
  }

  @override
  Future<void> sendGroupChatMessage(String groupId, GroupChatMessage message) async {
    _chat.putIfAbsent(groupId, () => []).add(message);
    _emitChat(groupId);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
