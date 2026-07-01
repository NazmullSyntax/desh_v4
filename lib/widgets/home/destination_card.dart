import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/tourist_place_model.dart';
import '../../providers/hotel_provider.dart' show favoritesProvider, toggleFavoriteProvider;
import '../common/app_network_image.dart';
import '../common/ui_atoms.dart';

/// Horizontal-scroll card used for Popular Destinations / Trending Places.
class DestinationCard extends ConsumerWidget {
  final TouristPlace place;
  final double width;

  const DestinationCard({super.key, required this.place, this.width = 200});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider).contains(place.id);

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.placeDetail}?id=${place.id}'),
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  url: place.coverImage,
                  width: width,
                  height: 130,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => ref.read(toggleFavoriteProvider)(place.id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavorite ? AppColors.accent : Colors.white,
                      ),
                    ),
                  ),
                ),
                if (place.averageRating > 0)
                  Positioned(bottom: 10, left: 10, child: RatingBadge(rating: place.averageRating, light: true)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          place.shortDescription,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
