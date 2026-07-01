import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/booking_model.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/common/primary_button.dart';

enum _Stage { processing, success, failed }

/// Drives the actual payment attempt via [PaymentRepository.pay] and shows
/// the appropriate loading/success/failure UI. On success (or immediately,
/// for Pay on Arrival), the booking is saved to [bookingsProvider].
class PaymentProcessingScreen extends ConsumerStatefulWidget {
  final Booking booking;
  const PaymentProcessingScreen({super.key, required this.booking});

  @override
  ConsumerState<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends ConsumerState<PaymentProcessingScreen> {
  _Stage _stage = _Stage.processing;
  String? _errorMessage;
  String? _transactionId;

  @override
  void initState() {
    super.initState();
    _process();
  }

  Future<void> _process() async {
    setState(() => _stage = _Stage.processing);
    final repo = ref.read(paymentRepositoryProvider);
    final result = await repo.pay(booking: widget.booking, method: widget.booking.paymentMethod);

    if (!mounted) return;

    if (result.success) {
      final status = widget.booking.paymentMethod == PaymentMethod.payOnArrival ? PaymentStatus.payLater : PaymentStatus.success;
      final confirmedBooking = widget.booking.copyWith(paymentStatus: status, transactionId: result.transactionId);
      ref.read(bookingsProvider.notifier).addBooking(confirmedBooking);
      setState(() {
        _stage = _Stage.success;
        _transactionId = result.transactionId;
      });
    } else {
      setState(() {
        _stage = _Stage.failed;
        _errorMessage = result.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: switch (_stage) {
            _Stage.processing => _ProcessingView(method: widget.booking.paymentMethod),
            _Stage.success => _SuccessView(booking: widget.booking, transactionId: _transactionId),
            _Stage.failed => _FailedView(errorMessage: _errorMessage, onRetry: _process),
          },
        ),
      ),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  final PaymentMethod method;
  const _ProcessingView({required this.method});

  @override
  Widget build(BuildContext context) {
    final isInstant = method == PaymentMethod.payOnArrival;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            isInstant ? 'Confirming your reservation...' : 'Processing your ${method.label} payment...',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (!isInstant) ...[
            const SizedBox(height: 8),
            Text(
              'Please don\'t close the app',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final Booking booking;
  final String? transactionId;
  const _SuccessView({required this.booking, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    final isPayLater = booking.paymentStatus == PaymentStatus.payLater;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
        ),
        const SizedBox(height: 24),
        Text(
          isPayLater ? 'Reservation Confirmed!' : 'Payment Successful!',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          isPayLater
              ? 'Your booking for ${booking.itemName} is reserved. Pay in cash or card at check-in.'
              : 'Your booking for ${booking.itemName} is confirmed.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (transactionId != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Theme.of(context).dividerColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Text('Transaction ID: $transactionId', style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'View My Bookings',
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            context.go(AppRoutes.bookings);
          },
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Back to Home'),
        ),
      ],
    );
  }
}

class _FailedView extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;
  const _FailedView({required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), shape: BoxShape.circle),
          child: const Icon(Icons.error_outline, color: AppColors.error, size: 56),
        ),
        const SizedBox(height: 24),
        Text('Payment Failed', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          errorMessage ?? 'Something went wrong while processing your payment.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        PrimaryButton(label: 'Try Again', onPressed: onRetry),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Choose a Different Method'),
        ),
      ],
    );
  }
}
