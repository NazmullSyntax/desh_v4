import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/booking_model.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/ui_atoms.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookings.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No bookings yet',
              subtitle: 'Hotel and transport bookings you make will show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: bookings.length,
              separatorBuilder: (context, i) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _BookingCard(booking: bookings[i]),
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  (Color, String, IconData) get _statusVisual {
    switch (booking.paymentStatus) {
      case PaymentStatus.success:
        return (AppColors.success, 'Paid', Icons.check_circle_outline);
      case PaymentStatus.payLater:
        return (AppColors.accentDark, 'Pay on Arrival', Icons.schedule_outlined);
      case PaymentStatus.processing:
      case PaymentStatus.pending:
        return (AppColors.secondary, 'Processing', Icons.hourglass_empty);
      case PaymentStatus.failed:
        return (AppColors.error, 'Failed', Icons.error_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final (statusColor, statusLabel, statusIcon) = _statusVisual;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppNetworkImage(url: booking.itemImageUrl, width: 56, height: 56, borderRadius: BorderRadius.circular(12)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.itemName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      '${dateFormat.format(booking.travelDate)} · ${booking.travelers} traveler${booking.travelers > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(formatBDT(booking.amount), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(statusLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
                ],
              ),
              Text(booking.paymentMethod.label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          if (booking.transactionId != null) ...[
            const SizedBox(height: 6),
            Text('Txn: ${booking.transactionId}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
          ],
        ],
      ),
    );
  }
}
