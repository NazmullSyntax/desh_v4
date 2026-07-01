import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/groups_repository.dart';
import '../../models/travel_group_model.dart';

/// Firestore implementation of [GroupsRepository].
///
/// Data layout:
///   `travelGroups/{groupId}`                — group document (see toJson)
///   `travelGroups/{groupId}/chat/{msgId}`    — group chat thread
///
/// Membership and pending requests are kept as arrays of small maps on the
/// group document itself (not sub-collections) since group sizes here are
/// small (a handful of travelers), which keeps join/leave a single atomic
/// document write instead of a multi-document transaction.
class FirestoreGroupsRepository implements GroupsRepository {
  final FirebaseFirestore _firestore;

  FirestoreGroupsRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _groups => _firestore.collection('travelGroups');

  TravelGroup _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return TravelGroup.fromJson(data);
  }

  String _normalize(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

  @override
  Stream<List<TravelGroup>> watchGroupsForPlace(String placeId) {
    return _groups.snapshots().map((snap) {
      final filtered = snap.docs
          .map(_fromDoc)
          .where((group) => group.matchesDestination(placeId: placeId))
          .toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    }).handleError((error) {
      print('Error watching groups for place $placeId: $error');
      return [];
    });
  }

  @override
  Stream<List<TravelGroup>> watchMyGroups(String uid) {
    // Firestore can't OR across "members contains uid" and "pendingRequests
    // contains uid" in one query, so this merges two listeners client-side.
    return _combineGroupStreams(
      _groups.where('memberUids', arrayContains: uid).snapshots(),
      _groups.where('pendingUids', arrayContains: uid).snapshots(),
    );
  }

  /// Combines two Firestore snapshot streams by emitting whenever either updates.
  /// Keeps track of the latest snapshot from each stream and merges results.
  Stream<List<TravelGroup>> _combineGroupStreams(
    Stream<QuerySnapshot<Map<String, dynamic>>> stream1,
    Stream<QuerySnapshot<Map<String, dynamic>>> stream2,
  ) {
    final controller = StreamController<List<TravelGroup>>.broadcast();
    
    var latestSnap1 = null;
    var latestSnap2 = null;
    
    void emitMerged() {
      if (latestSnap1 != null && latestSnap2 != null) {
        final byId = <String, TravelGroup>{};
        for (final d in latestSnap1.docs) {
          byId[d.id] = _fromDoc(d);
        }
        for (final d in latestSnap2.docs) {
          byId[d.id] = _fromDoc(d);
        }
        final list = byId.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(list);
      }
    }
    
    final sub1 = stream1.listen(
      (snap) {
        latestSnap1 = snap;
        emitMerged();
      },
      onError: (e) => controller.addError(e),
    );
    
    final sub2 = stream2.listen(
      (snap) {
        latestSnap2 = snap;
        emitMerged();
      },
      onError: (e) => controller.addError(e),
    );
    
    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };
    
    return controller.stream;
  }

  @override
  Stream<TravelGroup?> watchGroup(String groupId) {
    return _groups.doc(groupId).snapshots().map((doc) => doc.exists ? _fromDoc(doc) : null);
  }

  Map<String, dynamic> _withIndexFields(TravelGroup g) {
    final json = g.toJson();
    // Denormalized uid-only arrays purely so Firestore's `arrayContains`
    // can query membership without scanning the full member-profile maps.
    json['memberUids'] = g.members.map((m) => m.uid).toList();
    json['pendingUids'] = g.pendingRequests.map((m) => m.uid).toList();
    return json;
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
    final doc = _groups.doc();
    final group = TravelGroup(
      id: doc.id,
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
    await doc.set(_withIndexFields(group));
    await doc.collection('chat').add({
      'senderUid': 'system',
      'senderName': 'DeshExplorer',
      'text': 'Group created for "$title". Invite friends or wait for join requests!',
      'timestamp': FieldValue.serverTimestamp(),
    });
    return group;
  }

  Future<void> _updateGroup(String groupId, TravelGroup Function(TravelGroup current) update) async {
    await _firestore.runTransaction((tx) async {
      final ref = _groups.doc(groupId);
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final current = _fromDoc(snap);
      final next = update(current);
      tx.set(ref, _withIndexFields(next));
    });
  }

  @override
  Future<void> joinGroup(String groupId, GroupMemberProfile member) {
    return _updateGroup(groupId, (g) {
      if (g.isFull || g.isMember(member.uid)) return g;
      return g.copyWith(members: [...g.members, member]);
    });
  }

  @override
  Future<void> requestJoin(String groupId, GroupMemberProfile member) {
    return _updateGroup(groupId, (g) {
      if (g.isFull || g.isMember(member.uid) || g.hasPendingRequest(member.uid)) return g;
      return g.copyWith(pendingRequests: [...g.pendingRequests, member]);
    });
  }

  @override
  Future<void> approveRequest(String groupId, String uid) {
    return _updateGroup(groupId, (g) {
      final requester = g.pendingRequests.where((m) => m.uid == uid);
      if (requester.isEmpty || g.isFull) return g;
      return g.copyWith(
        members: [...g.members, requester.first],
        pendingRequests: g.pendingRequests.where((m) => m.uid != uid).toList(),
      );
    });
  }

  @override
  Future<void> rejectRequest(String groupId, String uid) {
    return _updateGroup(
      groupId,
      (g) => g.copyWith(pendingRequests: g.pendingRequests.where((m) => m.uid != uid).toList()),
    );
  }

  @override
  Future<void> leaveGroup(String groupId, String uid) {
    return _updateGroup(
      groupId,
      (g) => g.copyWith(members: g.members.where((m) => m.uid != uid).toList()),
    );
  }

  @override
  Stream<List<GroupChatMessage>> watchGroupChat(String groupId) {
    return _groups.doc(groupId).collection('chat').orderBy('timestamp').snapshots().map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            final ts = data['timestamp'];
            return GroupChatMessage(
              id: d.id,
              senderUid: data['senderUid'] as String? ?? 'unknown',
              senderName: data['senderName'] as String? ?? 'Traveler',
              text: data['text'] as String? ?? '',
              timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
            );
          }).toList(),
        );
  }

  @override
  Future<void> sendGroupChatMessage(String groupId, GroupChatMessage message) async {
    await _groups.doc(groupId).collection('chat').add({
      'senderUid': message.senderUid,
      'senderName': message.senderName,
      'text': message.text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
