import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/booking_model.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/primary_button.dart';
import 'payment_processing_screen.dart';

/// Checkout screen: shows a booking summary and lets the user pick a
/// Bangladesh payment method (bKash / Nagad / Rocket / Card) or default to
/// Pay on Arrival, which needs no payment integration at all.
///
/// This screen builds a [Booking] in `pending`/`payLater` state and hands
/// off to [PaymentProcessingScreen], which actually calls
/// [PaymentRepository.pay] — see that repository's doc comment for the
/// real-money-movement caveats before wiring up live merchant keys.
class CheckoutScreen extends ConsumerWidget {
  final BookingType type;
  final String itemId;
  final String itemName;
  final String itemImageUrl;
  final DateTime travelDate;
  final int travelers;
  final double amount;

  const CheckoutScreen({
    super.key,
    required this.type,
    required this.itemId,
    required this.itemName,
    required this.itemImageUrl,
    required this.travelDate,
    required this.travelers,
    required this.amount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMethod = ref.watch(selectedPaymentMethodProvider);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      AppNetworkImage(url: itemImageUrl, width: 64, height: 64, borderRadius: BorderRadius.circular(12)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(itemName, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('${dateFormat.format(travelDate)} · $travelers traveler${travelers > 1 ? 's' : ''}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Select Payment Method', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'All major Bangladesh mobile financial services are supported.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                ...PaymentMethod.values.map((method) => _PaymentMethodTile(
                      method: method,
                      isSelected: selectedMethod == method,
                      onTap: () => ref.read(selectedPaymentMethodProvider.notifier).state = method,
                    )),
                const SizedBox(height: 20),
                _AmountSummary(amount: amount),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                label: selectedMethod == PaymentMethod.payOnArrival
                    ? 'Confirm Reservation'
                    : 'Pay ${formatBDT(amount)} with ${selectedMethod.label}',
                onPressed: () {
                  final booking = createPendingBooking(
                    type: type,
                    itemId: itemId,
                    itemName: itemName,
                    itemImageUrl: itemImageUrl,
                    travelDate: travelDate,
                    travelers: travelers,
                    amount: amount,
                    method: selectedMethod,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PaymentProcessingScreen(booking: booking)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;
  const _PaymentMethodTile({required this.method, required this.isSelected, required this.onTap});

  Color get _brandColor {
    switch (method) {
      case PaymentMethod.bkash:
        return const Color(0xFFE2136E);
      case PaymentMethod.nagad:
        return const Color(0xFFF6921E);
      case PaymentMethod.rocket:
        return const Color(0xFF8C3494);
      case PaymentMethod.card:
        return AppColors.secondary;
      case PaymentMethod.payOnArrival:
        return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (method) {
      case PaymentMethod.bkash:
      case PaymentMethod.nagad:
      case PaymentMethod.rocket:
        return Icons.smartphone_outlined;
      case PaymentMethod.card:
        return Icons.credit_card_outlined;
      case PaymentMethod.payOnArrival:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? _brandColor.withValues(alpha: 0.08) : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? _brandColor : Theme.of(context).dividerColor, width: isSelected ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: _brandColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(_icon, color: _brandColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(method.subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? _brandColor : Theme.of(context).dividerColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountSummary extends StatelessWidget {
  final double amount;
  const _AmountSummary({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total Amount', style: Theme.of(context).textTheme.bodyMedium),
          Text(formatBDT(amount), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
