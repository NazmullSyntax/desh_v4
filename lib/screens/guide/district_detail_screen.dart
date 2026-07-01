import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_spacing.dart';
import '../../providers/guide_provider.dart';
import '../../widgets/common/ui_atoms.dart';
import '../../widgets/home/destination_card.dart';

/// Detail screen for one district: lists every curated [TouristPlace]
/// within it. Reached from [DistrictListScreen] or directly via a route
/// query parameter (`/guide/district?id=...`), e.g. from a deep link or a
/// "Nearby Attractions" tap on a place detail screen.
class DistrictDetailScreen extends ConsumerWidget {
  final String districtId;
  const DistrictDetailScreen({super.key, required this.districtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final districtAsync = ref.watch(districtByIdProvider(districtId));
    final placesAsync = ref.watch(placesForDistrictProvider(districtId));

    return Scaffold(
      appBar: AppBar(
        title: districtAsync.maybeWhen(data: (d) => Text(d?.name ?? 'District'), orElse: () => const Text('District')),
      ),
      body: placesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load this district.')),
        data: (places) {
          if (places.isEmpty) {
            return const EmptyState(
              icon: Icons.explore_off_outlined,
              title: 'No places listed yet',
              subtitle: 'We\'re still adding detailed guides for this district.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            itemCount: places.length,
            itemBuilder: (context, i) => DestinationCard(place: places[i], width: double.infinity),
          );
        },
      ),
    );
  }
}
