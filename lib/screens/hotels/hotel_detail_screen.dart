import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/booking_model.dart';
import '../../models/hotel_model.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/ui_atoms.dart';
import '../payment/checkout_screen.dart';

class HotelDetailScreen extends ConsumerWidget {
  final String hotelId;
  const HotelDetailScreen({super.key, required this.hotelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotelsAsync = ref.watch(allHotelsProvider);

    return Scaffold(
      body: hotelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load hotel.')),
        data: (hotels) {
          final matches = hotels.where((h) => h.id == hotelId);
          if (matches.isEmpty) return const Center(child: Text('Hotel not found.'));
          return _HotelDetailBody(hotel: matches.first);
        },
      ),
    );
  }
}class _HotelDetailBody extends StatelessWidget {
  final Hotel hotel;
  const _HotelDetailBody({required this.hotel});

  void _openBookingSheet(BuildContext context, Hotel hotel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BookingDetailsSheet(hotel: hotel),
    );
  }

  String get _typeLabel {
    switch (hotel.type) {
      case AccommodationType.hotel:
        return 'Hotel';
      case AccommodationType.resort:
        return 'Resort';
      case AccommodationType.guestHouse:
        return 'Guest House';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: AppNetworkImage(url: hotel.coverImage, fit: BoxFit.cover),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(hotel.name, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24))),
                    RatingBadge(rating: hotel.rating),
                  ],
                ),
                const SizedBox(height: 6),
                Text('$_typeLabel · ${hotel.reviewCount} reviews', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(hotel.address, style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Facilities', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: hotel.facilities.map((f) => Chip(label: Text(f), avatar: const Icon(Icons.check, size: 16))).toList(),
                ),
                const SizedBox(height: 20),
                Text('Contact', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(hotel.contactPhone, style: Theme.of(context).textTheme.bodyMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse('tel:${hotel.contactPhone}')),
                      child: const Text('Call'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatBDT(hotel.pricePerNight), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                            Text('per night', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: PrimaryButton(
                          label: 'Book Now',
                          onPressed: () => _openBookingSheet(context, hotel),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Lets the user pick a check-in date and number of nights/travelers
/// before heading to checkout. Kept intentionally simple (a real booking
/// engine would check live room availability) — this captures everything
/// [CheckoutScreen] needs to build a [Booking].
class _BookingDetailsSheet extends StatefulWidget {
  final Hotel hotel;
  const _BookingDetailsSheet({required this.hotel});

  @override
  State<_BookingDetailsSheet> createState() => _BookingDetailsSheetState();
}

class _BookingDetailsSheetState extends State<_BookingDetailsSheet> {
  DateTime _checkIn = DateTime.now().add(const Duration(days: 7));
  int _nights = 1;
  int _travelers = 2;

  double get _totalAmount => widget.hotel.pricePerNight * _nights;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book ${widget.hotel.name}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),

            _SheetFieldRow(
              icon: Icons.calendar_today_outlined,
              label: 'Check-in Date',
              value: dateFormat.format(_checkIn),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _checkIn,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _checkIn = picked);
              },
            ),
            const SizedBox(height: 14),
            _SheetStepperRow(
              icon: Icons.nights_stay_outlined,
              label: 'Nights',
              value: _nights,
              onChanged: (v) => setState(() => _nights = v.clamp(1, 30)),
            ),
            const SizedBox(height: 14),
            _SheetStepperRow(
              icon: Icons.groups_outlined,
              label: 'Travelers',
              value: _travelers,
              onChanged: (v) => setState(() => _travelers = v.clamp(1, 10)),
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total ($_nights night${_nights > 1 ? 's' : ''})', style: Theme.of(context).textTheme.bodyMedium),
                  Text(formatBDT(_totalAmount), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Continue to Payment',
              onPressed: () {
                Navigator.of(context).pop(); // close sheet
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(
                      type: BookingType.hotel,
                      itemId: widget.hotel.id,
                      itemName: widget.hotel.name,
                      itemImageUrl: widget.hotel.coverImage,
                      travelDate: _checkIn,
                      travelers: _travelers,
                      amount: _totalAmount,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SheetFieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _SheetFieldRow({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _SheetStepperRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _SheetStepperRow({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          IconButton(onPressed: () => onChanged(value - 1), icon: const Icon(Icons.remove_circle_outline)),
          Text('$value', style: Theme.of(context).textTheme.titleMedium),
          IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add_circle_outline)),
        ],
      ),
    );
  }
}

