import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/support_repository.dart';
import '../../models/support_ticket_model.dart';

const _uuid = Uuid();

class FirestoreSupportRepository implements SupportRepository {
  final FirebaseFirestore _firestore;

  FirestoreSupportRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tickets => _firestore.collection('supportTickets');

  SupportTicket _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return SupportTicket.fromJson(data);
  }

  @override
  Stream<List<SupportTicket>> watchAllTickets() {
    return _tickets.orderBy('createdAt', descending: true).snapshots().map(
      (snap) => snap.docs.map(_fromDoc).toList(),
    ).handleError((error) {
      debugPrint('Error watching all tickets: $error');
      return [];
    });
  }

  @override
  Stream<SupportTicket?> watchTicket(String ticketId) {
    return _tickets.doc(ticketId).snapshots().map(
      (doc) => doc.exists ? _fromDoc(doc) : null,
    );
  }

  @override
  Stream<List<SupportTicket>> watchUserTickets(String userId) {
    return _tickets.where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots().map(
      (snap) => snap.docs.map(_fromDoc).toList(),
    ).handleError((error) {
      debugPrint('Error watching user tickets: $error');
      return [];
    });
  }

  @override
  Future<void> addUserMessage({
    required String userId,
    required String destinationName,
    required String tripId,
    required String message,
  }) async {
    // Find or create a ticket for this trip
    final existing = await _tickets
        .where('userId', isEqualTo: userId)
        .where('tripId', isEqualTo: tripId)
        .limit(1)
        .get();

    final ticketId = existing.docs.isNotEmpty ? existing.docs.first.id : _uuid.v4();

    final newMessage = SupportChatMessage(
      id: _uuid.v4(),
      sender: userId,
      senderType: SupportChatSender.user,
      text: message,
      timestamp: DateTime.now(),
    );

    if (existing.docs.isNotEmpty) {
      // Append to existing ticket
      await _tickets.doc(ticketId).update({
        'messages': FieldValue.arrayUnion([newMessage.toJson()]),
      });
    } else {
      // Create new ticket
      await _tickets.doc(ticketId).set({
        'userId': userId,
        'destinationName': destinationName,
        'tripId': tripId,
        'messages': [newMessage.toJson()],
        'createdAt': DateTime.now().toIso8601String(),
        'isResolved': false,
      });
    }
  }

  @override
  Future<void> addAdminReply(String ticketId, String message) async {
    final newMessage = SupportChatMessage(
      id: _uuid.v4(),
      sender: 'admin',
      senderType: SupportChatSender.admin,
      text: message,
      timestamp: DateTime.now(),
    );

    await _tickets.doc(ticketId).update({
      'messages': FieldValue.arrayUnion([newMessage.toJson()]),
    });
  }

  @override
  Future<void> resolveTicket(String ticketId) async {
    await _tickets.doc(ticketId).update({'isResolved': true});
  }
}
