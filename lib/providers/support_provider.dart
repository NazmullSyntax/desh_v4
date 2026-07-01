import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../data/repositories/firestore_support_repository.dart';
import '../data/repositories/mock_support_repository.dart';
import '../domain/repositories/support_repository.dart';
import '../models/support_ticket_model.dart';
import 'auth_provider.dart';

/// Provides the active [SupportRepository] implementation.
final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirestoreSupportRepository();
  }
  return MockSupportRepository();
});

/// Streams all support tickets (admin view).
final allSupportTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  return ref.watch(supportRepositoryProvider).watchAllTickets();
});

/// Streams a single ticket's details.
final supportTicketProvider = StreamProvider.family<SupportTicket?, String>((ref, ticketId) {
  return ref.watch(supportRepositoryProvider).watchTicket(ticketId);
});

/// Streams the current user's support tickets.
final userSupportTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(supportRepositoryProvider).watchUserTickets(user.uid);
});

/// Action provider for support operations.
class SupportActions {
  final Ref _ref;
  SupportActions(this._ref);

  Future<bool> addUserMessage({
    required String destinationName,
    required String tripId,
    required String message,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      return false;
    }
    await _ref.read(supportRepositoryProvider).addUserMessage(
          userId: user.uid,
          destinationName: destinationName,
          tripId: tripId,
          message: message,
        );
    return true;
  }

  Future<void> addAdminReply(String ticketId, String message) async {
    await _ref.read(supportRepositoryProvider).addAdminReply(ticketId, message);
  }

  Future<void> resolveTicket(String ticketId) async {
    await _ref.read(supportRepositoryProvider).resolveTicket(ticketId);
  }
}

final supportActionsProvider = Provider<SupportActions>((ref) => SupportActions(ref));
