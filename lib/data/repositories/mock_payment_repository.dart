import 'dart:math';
import '../../domain/repositories/payment_repository.dart';
import '../../models/booking_model.dart';

/// Mock payment backend used until a real merchant integration is wired
/// up (see the warning in payment_repository.dart about why bKash/Nagad/
/// Rocket need a server in between, never direct-from-app credentials).
///
/// - "Pay on Arrival" always succeeds instantly — it's just a reservation,
///   no money moves, so there's nothing to simulate.
/// - bKash / Nagad / Rocket / Card simulate a brief processing delay and a
///   95% success rate, generating a fake-but-realistic transaction ID, so
///   the full checkout UX (loading, success, retry-on-failure) can be
///   demoed and tested end-to-end before real credentials exist.
class MockPaymentRepository implements PaymentRepository {
  final _random = Random();

  @override
  Future<PaymentResult> pay({
    required Booking booking,
    required PaymentMethod method,
  }) async {
    if (method == PaymentMethod.payOnArrival) {
      await Future.delayed(const Duration(milliseconds: 400));
      return const PaymentResult(success: true, transactionId: null);
    }

    // Simulate gateway round-trip time.
    await Future.delayed(const Duration(seconds: 2));

    final succeeded = _random.nextDouble() < 0.95;
    if (succeeded) {
      final prefix = switch (method) {
        PaymentMethod.bkash => 'BKS',
        PaymentMethod.nagad => 'NGD',
        PaymentMethod.rocket => 'RKT',
        PaymentMethod.card => 'CRD',
        PaymentMethod.payOnArrival => 'POA',
      };
      final txnId = '$prefix${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      return PaymentResult(success: true, transactionId: txnId);
    }

    return const PaymentResult(
      success: false,
      errorMessage: 'Payment could not be completed. Please check your balance/PIN and try again.',
    );
  }
}
