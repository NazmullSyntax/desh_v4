import '../../models/support_ticket_model.dart';

/// Domain-layer contract for support ticketing.
abstract class SupportRepository {
  /// Stream all support tickets (admin view).
  Stream<List<SupportTicket>> watchAllTickets();

  /// Stream a single ticket's messages.
  Stream<SupportTicket?> watchTicket(String ticketId);

  /// Stream the current user's support tickets.
  Stream<List<SupportTicket>> watchUserTickets(String userId);

  /// Create or update a support ticket with a new user message.
  Future<void> addUserMessage({
    required String userId,
    required String destinationName,
    required String tripId,
    required String message,
  });

  /// Add an admin reply to a ticket.
  Future<void> addAdminReply(String ticketId, String message);

  /// Mark a ticket as resolved.
  Future<void> resolveTicket(String ticketId);
}
