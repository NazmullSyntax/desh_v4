import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/repositories/mock_payment_repository.dart';
import '../domain/repositories/payment_repository.dart';
import '../models/booking_model.dart';

const _uuid = Uuid();

/// Provides the active [PaymentRepository]. There's no `useFirebase`-style
/// flag here on purpose — Firebase has nothing to do with payments. Once
/// you have a real backend endpoint for bKash/Nagad/Rocket/card, write a
/// new implementation (e.g. `BackendPaymentRepository`) that calls it, and
/// swap it in here. See domain/repositories/payment_repository.dart for
/// why that backend hop is required and can't be skipped.
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return MockPaymentRepository();
});

/// Selected payment method on the checkout screen, defaulting to "Pay on
/// Arrival" so a first-time user always has a zero-setup path to complete
/// a booking.
final selectedPaymentMethodProvider = StateProvider<PaymentMethod>((ref) => PaymentMethod.payOnArrival);

/// All bookings made by the current user (in-memory for this build;
/// persist via Firestore by following the same pattern as other
/// repositories once ready — see SETUP_INSTRUCTIONS.md).
class BookingsController extends StateNotifier<List<Booking>> {
  BookingsController() : super([]);

  void addBooking(Booking booking) {
    state = [booking, ...state];
  }

  void updateBookingStatus(String id, PaymentStatus status, {String? transactionId}) {
    state = state.map((b) {
      if (b.id != id) return b;
      return b.copyWith(paymentStatus: status, transactionId: transactionId);
    }).toList();
  }
}

final bookingsProvider = StateNotifierProvider<BookingsController, List<Booking>>((ref) {
  return BookingsController();
});

/// Creates a [Booking] in `pending` state and returns it — call this
/// before kicking off payment so there's always a record, even if payment
/// fails or the user backs out.
Booking createPendingBooking({
  required BookingType type,
  required String itemId,
  required String itemName,
  required String itemImageUrl,
  required DateTime travelDate,
  required int travelers,
  required double amount,
  required PaymentMethod method,
}) {
  return Booking(
    id: _uuid.v4(),
    type: type,
    itemId: itemId,
    itemName: itemName,
    itemImageUrl: itemImageUrl,
    travelDate: travelDate,
    travelers: travelers,
    amount: amount,
    paymentMethod: method,
    paymentStatus: method == PaymentMethod.payOnArrival ? PaymentStatus.payLater : PaymentStatus.pending,
    createdAt: DateTime.now(),
  );
}
