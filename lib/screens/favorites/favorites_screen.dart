import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_spacing.dart';
import '../../providers/guide_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/common/ui_atoms.dart';
import '../../widgets/home/destination_card.dart';

/// Shows every [TouristPlace] the user has favorited. Favorites are
/// backed by [FavoritesRepository] (Firestore once `useFirebase = true`,
/// an in-memory mock otherwise) — see lib/providers/hotel_provider.dart.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    final placesAsync = ref.watch(allTouristPlacesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: placesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load favorites.')),
        data: (allPlaces) {
          final favoritePlaces = allPlaces.where((p) => favoriteIds.contains(p.id)).toList();

          if (favoritePlaces.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              subtitle: 'Tap the heart icon on any destination to save it here.',
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
            itemCount: favoritePlaces.length,
            itemBuilder: (context, i) => DestinationCard(place: favoritePlaces[i], width: double.infinity),
          );
        },
      ),
    );
  }
}
