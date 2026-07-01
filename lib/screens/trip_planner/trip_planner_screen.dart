import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/trip_plan_model.dart';
import '../../providers/guide_provider.dart';
import '../../providers/trip_planner_provider.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/ui_atoms.dart';
import '../support/live_chat_screen.dart';
import 'trip_result_screen.dart';

/// Trip Planner module: lets the user pick a destination, dates, budget,
/// travelers, and transport, then generates a day-by-day itinerary plus a
/// full cost breakdown (see [TripResultScreen]).
class TripPlannerScreen extends ConsumerWidget {
  const TripPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final savedTrips = ref.watch(savedTripsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Planner')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text('Plan a new trip', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Pick a destination and dates — we\'ll build the itinerary and budget for you.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),

          _DestinationPicker(),
          const SizedBox(height: 16),
          _DatePicker(),
          const SizedBox(height: 16),
          _TravelersStepper(),
          const SizedBox(height: 16),
          _TransportSelector(),
          const SizedBox(height: 16),
          _BudgetSlider(),
          const SizedBox(height: 28),

          PrimaryButton(
            label: 'Generate Itinerary',
            icon: Icons.auto_awesome,
            onPressed: draft.isComplete
                ? () {
                    final plan = buildTripPlan(draft);
                    ref.read(saveTripProvider)(plan);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TripResultScreen(plan: plan)),
                    );
                  }
                : null,
          ),
          if (!draft.isComplete)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Select a destination and travel dates to continue.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 32),
          Text('My Saved Trips', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (savedTrips.isEmpty)
            const EmptyState(icon: Icons.card_travel_outlined, title: 'No trips yet', subtitle: 'Trips you generate will appear here')
          else
            ...savedTrips.map((trip) => _SavedTripTile(trip: trip)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _DestinationPicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final divisionsAsync = ref.watch(divisionsProvider);

    return _FieldCard(
      icon: Icons.place_outlined,
      label: 'Destination',
      value: draft.destinationName ?? 'Select a district',
      onTap: () async {
        final divisions = divisionsAsync.value ?? [];
        if (divisions.isEmpty) return;

        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => _DestinationSheet(divisions: divisions),
        );
      },
    );
  }
}

class _DestinationSheet extends ConsumerWidget {
  final List divisions;
  const _DestinationSheet({required this.divisions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose a destination', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: divisions.length,
                  itemBuilder: (context, i) {
                    final division = divisions[i];
                    return Consumer(
                      builder: (context, ref, _) {
                        final districtsAsync = ref.watch(districtsForDivisionProvider(division.id));
                        return districtsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (e, st) => const SizedBox.shrink(),
                          data: (districts) {
                            final richDistricts = districts.where((d) => d.hasRichData).toList();
                            if (richDistricts.isEmpty) return const SizedBox.shrink();
                            return ExpansionTile(
                              title: Text(division.name),
                              children: richDistricts.map((d) {
                                return ListTile(
                                  title: Text(d.name),
                                  onTap: () {
                                    ref.read(tripDraftProvider.notifier).setDestination(d.id, d.name);
                                    Navigator.of(context).pop();
                                  },
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DatePicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final formatter = DateFormat('MMM d, yyyy');
    final label = draft.startDate != null && draft.endDate != null
        ? '${formatter.format(draft.startDate!)} - ${formatter.format(draft.endDate!)}  (${draft.durationDays} days)'
        : 'Select travel dates';

    return _FieldCard(
      icon: Icons.calendar_today_outlined,
      label: 'Travel Dates',
      value: label,
      onTap: () async {
        final now = DateTime.now();
        final range = await showDateRangePicker(
          context: context,
          firstDate: now,
          lastDate: now.add(const Duration(days: 365)),
          initialDateRange: draft.startDate != null && draft.endDate != null
              ? DateTimeRange(start: draft.startDate!, end: draft.endDate!)
              : DateTimeRange(start: now.add(const Duration(days: 7)), end: now.add(const Duration(days: 10))),
        );
        if (range != null) {
          ref.read(tripDraftProvider.notifier).setDates(range.start, range.end);
        }
      },
    );
  }
}

class _TravelersStepper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final controller = ref.read(tripDraftProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Number of Travelers', style: Theme.of(context).textTheme.bodySmall),
                Text('${draft.travelers}', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          IconButton(onPressed: () => controller.setTravelers(draft.travelers - 1), icon: const Icon(Icons.remove_circle_outline)),
          IconButton(onPressed: () => controller.setTravelers(draft.travelers + 1), icon: const Icon(Icons.add_circle_outline)),
        ],
      ),
    );
  }
}

class _TransportSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final controller = ref.read(tripDraftProvider.notifier);

    final modes = [
      (TransportMode.bus, 'Bus', Icons.directions_bus_outlined),
      (TransportMode.train, 'Train', Icons.train_outlined),
      (TransportMode.flight, 'Flight', Icons.flight_outlined),
      (TransportMode.launch, 'Launch', Icons.directions_boat_outlined),
      (TransportMode.privateCar, 'Private Car', Icons.directions_car_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transportation', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: modes.length,
            separatorBuilder: (context, i) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final (mode, label, icon) = modes[i];
              final isSelected = draft.transportMode == mode;
              return GestureDetector(
                onTap: () => controller.setTransportMode(mode),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.primary : Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: isSelected ? Colors.white : null),
                      const SizedBox(width: 6),
                      Text(label, style: TextStyle(color: isSelected ? Colors.white : null, fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BudgetSlider extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final controller = ref.read(tripDraftProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Budget Cap', style: Theme.of(context).textTheme.bodySmall),
            Text(formatBDT(draft.budgetCap), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
        Slider(
          value: draft.budgetCap,
          min: 2000,
          max: 100000,
          divisions: 49,
          activeColor: AppColors.primary,
          onChanged: (v) => controller.setBudgetCap(v),
        ),
      ],
    );
  }
}

class _FieldCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _FieldCard({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
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

class _SavedTripTile extends StatelessWidget {
  final TripPlan trip;
  const _SavedTripTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripResultScreen(plan: trip))),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.card_travel, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.destinationName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      '${formatter.format(trip.startDate)} - ${formatter.format(trip.endDate)} · ${trip.travelers} travelers',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatBDT(trip.estimate.total), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  IconButton(
                    tooltip: 'Live Chat',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LiveChatScreen(destinationName: trip.destinationName, tripId: trip.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.support_agent_outlined, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
