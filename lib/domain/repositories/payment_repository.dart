import '../../models/booking_model.dart';

/// Result of initiating a payment — what the UI needs to know to either
/// show success, redirect to a gateway checkout page, or show an error.
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? redirectUrl; // some gateways need a webview/browser hop
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    this.transactionId,
    this.redirectUrl,
    this.errorMessage,
  });
}

/// Domain-layer contract for taking payment on a [Booking].
///
/// IMPORTANT — read before wiring up real money movement:
/// bKash, Nagad, and Rocket all require a registered merchant account and
/// a SERVER-SIDE integration (their checkout APIs need a secret app key/
/// signed request that must never ship inside a mobile app binary). This
/// interface is intentionally backend-agnostic: a real implementation
/// should call YOUR OWN backend (e.g. a Cloud Function), which in turn
/// talks to the payment gateway and returns a transaction result here.
/// Never call bKash/Nagad/Rocket REST APIs directly from Flutter with
/// embedded secrets — that's a critical security mistake, not just a
/// style preference.
///
/// Card payments typically go through a PCI-compliant SDK (e.g. Stripe,
/// SSLCommerz, ShurjoPay — all popular in Bangladesh) rather than raw
/// card fields; same "call your backend" principle applies.
abstract class PaymentRepository {
  Future<PaymentResult> pay({
    required Booking booking,
    required PaymentMethod method,
  });
}
