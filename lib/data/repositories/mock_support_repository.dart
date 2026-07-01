import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/repositories/support_repository.dart';
import '../../models/support_ticket_model.dart';

const _uuid = Uuid();

class MockSupportRepository implements SupportRepository {
  final Map<String, SupportTicket> _tickets = {};
  final _controller = StreamController<List<SupportTicket>>.broadcast();

  void _emit() {
    final sorted = _tickets.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _controller.add(sorted);
  }

  @override
  Stream<List<SupportTicket>> watchAllTickets() {
    Future.microtask(_emit);
    return _controller.stream;
  }

  @override
  Stream<SupportTicket?> watchTicket(String ticketId) {
    return Stream.value(_tickets[ticketId]);
  }

  @override
  Stream<List<SupportTicket>> watchUserTickets(String userId) {
    Future.microtask(_emit);
    return _controller.stream.map((all) => all.where((t) => t.userId == userId).toList());
  }

  @override
  Future<void> addUserMessage({
    required String userId,
    required String destinationName,
    required String tripId,
    required String message,
  }) async {
    final key = '$userId-$tripId';
    final existing = _tickets[key];

    final newMessage = SupportChatMessage(
      id: _uuid.v4(),
      sender: userId,
      senderType: SupportChatSender.user,
      text: message,
      timestamp: DateTime.now(),
    );

    if (existing != null) {
      _tickets[key] = existing.copyWith(messages: [...existing.messages, newMessage]);
    } else {
      _tickets[key] = SupportTicket(
        id: key,
        userId: userId,
        destinationName: destinationName,
        tripId: tripId,
        messages: [newMessage],
        createdAt: DateTime.now(),
      );
    }
    _emit();
  }

  @override
  Future<void> addAdminReply(String ticketId, String message) async {
    final ticket = _tickets[ticketId];
    if (ticket == null) return;

    final newMessage = SupportChatMessage(
      id: _uuid.v4(),
      sender: 'admin',
      senderType: SupportChatSender.admin,
      text: message,
      timestamp: DateTime.now(),
    );

    _tickets[ticketId] = ticket.copyWith(messages: [...ticket.messages, newMessage]);
    _emit();
  }

  @override
  Future<void> resolveTicket(String ticketId) async {
    final ticket = _tickets[ticketId];
    if (ticket == null) return;
    _tickets[ticketId] = ticket.copyWith(isResolved: true);
    _emit();
  }
}

extension on SupportTicket {
  SupportTicket copyWith({
    List<SupportChatMessage>? messages,
    bool? isResolved,
  }) {
    return SupportTicket(
      id: id,
      userId: userId,
      destinationName: destinationName,
      tripId: tripId,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}
