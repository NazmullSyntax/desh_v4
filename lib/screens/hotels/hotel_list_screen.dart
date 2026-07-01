import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/hotel_model.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/ui_atoms.dart';

class HotelListScreen extends ConsumerStatefulWidget {
  const HotelListScreen({super.key});

  @override
  ConsumerState<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends ConsumerState<HotelListScreen> {
  AccommodationType? _filter;

  @override
  Widget build(BuildContext context) {
    final hotelsAsync = ref.watch(allHotelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hotels & Stays')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 12),
            child: Row(
              children: [
                _FilterChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Hotels', selected: _filter == AccommodationType.hotel, onTap: () => setState(() => _filter = AccommodationType.hotel)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Resorts', selected: _filter == AccommodationType.resort, onTap: () => setState(() => _filter = AccommodationType.resort)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Guest Houses', selected: _filter == AccommodationType.guestHouse, onTap: () => setState(() => _filter = AccommodationType.guestHouse)),
              ],
            ),
          ),
          Expanded(
            child: hotelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const Center(child: Text('Could not load hotels.')),
              data: (hotels) {
                final filtered = _filter == null ? hotels : hotels.where((h) => h.type == _filter).toList();
                if (filtered.isEmpty) {
                  return const EmptyState(icon: Icons.hotel_outlined, title: 'No stays found', subtitle: 'Try a different filter');
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 14),
                  itemBuilder: (context, i) => _HotelCard(hotel: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Theme.of(context).dividerColor),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : null, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  final Hotel hotel;
  const _HotelCard({required this.hotel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.hotelDetail}?id=${hotel.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            AppNetworkImage(
              url: hotel.coverImage,
              width: 110,
              height: 110,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hotel.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingBadge(rating: hotel.rating),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('(${hotel.reviewCount})', style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hotel.address,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatBDT(hotel.pricePerNight)} / night',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
