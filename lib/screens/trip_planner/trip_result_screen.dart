import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/booking_model.dart';
import '../../models/trip_plan_model.dart';
import '../../widgets/common/primary_button.dart';
import '../payment/checkout_screen.dart';
import '../support/live_chat_screen.dart';

IconData _iconForKey(String key) {
  switch (key) {
    case 'directions_bus':
      return Icons.directions_bus_outlined;
    case 'hotel':
      return Icons.hotel_outlined;
    case 'directions_walk':
      return Icons.directions_walk_outlined;
    case 'photo_camera':
      return Icons.photo_camera_outlined;
    case 'restaurant':
      return Icons.restaurant_outlined;
    case 'place':
      return Icons.place_outlined;
    case 'hiking':
      return Icons.hiking_outlined;
    case 'nightlife':
      return Icons.nightlife_outlined;
    default:
      return Icons.circle_outlined;
  }
}

/// Shows the generated itinerary (day-by-day) and full budget breakdown
/// for a [TripPlan]. Reached after "Generate Itinerary" on the Trip
/// Planner screen, or by tapping a saved trip.
class TripResultScreen extends StatelessWidget {
  final TripPlan plan;
  const TripResultScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(plan.destinationName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.destinationName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  '${formatter.format(plan.startDate)} - ${formatter.format(plan.endDate)}',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatChip(icon: Icons.groups_outlined, label: '${plan.travelers} travelers'),
                    const SizedBox(width: 10),
                    _StatChip(icon: Icons.calendar_today_outlined, label: '${plan.durationDays} days'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text('Budget Breakdown', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _BudgetCard(estimate: plan.estimate, cap: plan.budgetCap),

          const SizedBox(height: 28),
          Text('Day-by-Day Itinerary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...plan.itinerary.map((day) => _ItineraryDayCard(day: day)),

          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Book This Trip',
            icon: Icons.payments_outlined,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CheckoutScreen(
                  type: BookingType.transport,
                  itemId: plan.destinationDistrictId,
                  itemName: '${plan.destinationName} Trip',
                  itemImageUrl: 'https://picsum.photos/seed/deshexplorer-district-${plan.destinationDistrictId}/600/600',
                  travelDate: plan.startDate,
                  travelers: plan.travelers,
                  amount: plan.estimate.total,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Books transport + estimated costs for this trip as a single reservation.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LiveChatScreen(destinationName: plan.destinationName, tripId: plan.id),
                ),
              );
            },
            icon: const Icon(Icons.support_agent_outlined),
            label: const Text('Live Chat'),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetEstimate estimate;
  final double cap;
  const _BudgetCard({required this.estimate, required this.cap});

  static const _colors = [AppColors.primary, AppColors.secondary, AppColors.accent, AppColors.error, AppColors.secondaryDark];

  @override
  Widget build(BuildContext context) {
    final breakdown = estimate.breakdown;
    final isOverBudget = estimate.total > cap;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Estimated Budget', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${formatBDT(estimate.total)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (isOverBudget) ...[
            const SizedBox(height: 6),
            Text(
              'This exceeds your ${formatBDT(cap)} budget cap by ${formatBDT(estimate.total - cap)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: breakdown.entries.map((e) {
                  final index = breakdown.keys.toList().indexOf(e.key);
                  final flex = (e.value / estimate.total * 1000).round().clamp(1, 1000);
                  return Expanded(flex: flex, child: Container(color: _colors[index % _colors.length]));
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...breakdown.entries.map((e) {
            final index = breakdown.keys.toList().indexOf(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: _colors[index % _colors.length], shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.key, style: Theme.of(context).textTheme.bodyMedium)),
                  Text(formatBDT(e.value), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ItineraryDayCard extends StatelessWidget {
  final ItineraryDay day;
  const _ItineraryDayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text('${day.dayNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Text(day.title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          ...day.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(item.time, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(_iconForKey(item.icon), size: 15, color: AppColors.primary),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text(item.description, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
