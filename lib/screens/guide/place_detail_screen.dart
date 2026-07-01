import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../models/tourist_place_model.dart';
import '../../models/travel_group_model.dart';
import '../../providers/guide_provider.dart';
import '../../providers/groups_provider.dart';
import '../../providers/hotel_provider.dart' show favoritesProvider, toggleFavoriteProvider;
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/fullscreen_gallery_viewer.dart';
import '../../widgets/common/ui_atoms.dart';
import '../groups/create_group_screen.dart';
import '../groups/groups_for_place_screen.dart';
import '../maps/place_map_screen.dart';

class PlaceDetailScreen extends ConsumerWidget {
  final String placeId;
  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeAsync = ref.watch(placeByIdProvider(placeId));

    return Scaffold(
      body: placeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load this place.')),
        data: (place) {
          if (place == null) {
            return const Center(child: Text('Place not found.'));
          }
          return _PlaceDetailBody(place: place);
        },
      ),
    );
  }
}

class _PlaceDetailBody extends ConsumerWidget {
  final TouristPlace place;
  const _PlaceDetailBody({required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider).contains(place.id);
    final coverImage = place.imageUrls.isNotEmpty ? place.imageUrls.first : place.coverImage;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateGroupScreen(placeId: place.id, destinationName: place.name, coverImage: coverImage),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Start Trip'),
        backgroundColor: AppColors.primary,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              IconButton(
                onPressed: () => ref.read(toggleFavoriteProvider)(place.id),
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? AppColors.accent : Colors.white),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined, color: Colors.white)),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _PhotoGallery(imageUrls: place.imageUrls.isNotEmpty ? place.imageUrls : [place.coverImage]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place.name, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26)),
                            Text(place.banglaName, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      if (place.averageRating > 0) RatingBadge(rating: place.averageRating),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: place.category.map((c) => Chip(label: Text(c))).toList(),
                  ),
                  const SizedBox(height: 18),
                  Text(place.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),

                  const SizedBox(height: 24),
                  _InfoGrid(place: place),

                  const SizedBox(height: 24),
                  _TravelersPlanningSection(place: place),

                  const SizedBox(height: 24),
                  if (place.history.isNotEmpty) _ExpandableSection(title: 'History', content: place.history, icon: Icons.history_edu_outlined),

                  if (place.travelTips.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Travel Tips', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    ...place.travelTips.map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(tip, style: Theme.of(context).textTheme.bodyMedium)),
                            ],
                          ),
                        )),
                  ],

                  const SizedBox(height: 24),
                  Text('Location', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  _MapPreviewCard(place: place),

                  if (place.nearbyHotels.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'Hotels Nearby'),
                    _NearbyRow(items: place.nearbyHotels),
                  ],

                  if (place.nearbyRestaurants.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'Restaurants Nearby'),
                    _NearbyRow(items: place.nearbyRestaurants),
                  ],

                  if (place.nearbyAttractions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'Nearby Attractions'),
                    _NearbyRow(items: place.nearbyAttractions),
                  ],

                  if (place.emergencyContacts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Emergency Contacts', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    ...place.emergencyContacts.map((c) => _EmergencyContactTile(contact: c)),
                  ],

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('User Reviews', style: Theme.of(context).textTheme.titleLarge),
                      Text('${place.reviews.length} reviews', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (place.reviews.isEmpty)
                    const EmptyState(icon: Icons.rate_review_outlined, title: 'No reviews yet', subtitle: 'Be the first to review this place')
                  else
                    ...place.reviews.map((r) => _ReviewTile(review: r)),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelersPlanningSection extends ConsumerWidget {
  final TouristPlace place;
  const _TravelersPlanningSection({required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsForPlaceProvider(place.id));
    final coverImage = place.imageUrls.isNotEmpty ? place.imageUrls.first : place.coverImage;

    return groupsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (groups) {
        final travelerCount = groups.fold<int>(0, (sum, g) => sum + g.members.length);

        return Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      groups.isEmpty
                          ? 'Be the first to plan a trip here'
                          : '$travelerCount ${travelerCount == 1 ? 'Traveler' : 'Travelers'} Currently Planning This Trip',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Join a group, meet fellow solo travelers, or start your own.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5),
              ),
              if (groups.isNotEmpty) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 34,
                  child: Stack(
                    children: [
                      for (int i = 0; i < _uniqueMembers(groups).take(6).length; i++)
                        Positioned(
                          left: i * 22.0,
                          child: CircleAvatar(
                            radius: 17,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.white24,
                              child: Text(
                                _uniqueMembers(groups)[i].name.isNotEmpty ? _uniqueMembers(groups)[i].name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupsForPlaceScreen(placeId: place.id, destinationName: place.name, coverImage: coverImage),
                        ),
                      ),
                      child: Text(groups.isEmpty ? 'Browse Groups' : 'View ${groups.length} ${groups.length == 1 ? 'Group' : 'Groups'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CreateGroupScreen(placeId: place.id, destinationName: place.name, coverImage: coverImage),
                        ),
                      ),
                      child: const Text('Create Trip', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<GroupMemberProfile> _uniqueMembers(List<TravelGroup> groups) {
    final seen = <String>{};
    final result = <GroupMemberProfile>[];
    for (final g in groups) {
      for (final m in g.members) {
        if (seen.add(m.uid)) result.add(m);
      }
    }
    return result;
  }
}

class _PhotoGallery extends StatefulWidget {
  final List<String> imageUrls;
  const _PhotoGallery({required this.imageUrls});

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: widget.imageUrls.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => FullscreenGalleryViewer.open(
              context,
              imageUrls: widget.imageUrls,
              initialIndex: i,
            ),
            child: AppNetworkImage(url: widget.imageUrls[i], fit: BoxFit.cover),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imageUrls.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final TouristPlace place;
  const _InfoGrid({required this.place});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.payments_outlined, 'Entry Fee', place.entryFee),
      (Icons.schedule_outlined, 'Opening Hours', place.openingHours),
      (Icons.calendar_today_outlined, 'Best Time', place.bestTimeToVisit),
      (Icons.social_distance_outlined, 'Distance from Dhaka', '${place.distanceFromDhakaKm.toStringAsFixed(0)} km'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.4,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final (icon, label, value) = items[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final String content;
  final IconData icon;
  const _ExpandableSection({required this.title, required this.content, required this.icon});

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
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
                Icon(widget.icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleMedium)),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(widget.content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
              ),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  final TouristPlace place;
  const _MapPreviewCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlaceMapScreen(place: place)),
      ),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 48, color: AppColors.primary),
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                child: const Text('Open in Maps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyRow extends StatelessWidget {
  final List<NearbyRef> items;
  const _NearbyRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, i) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          return Container(
            width: 220,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                AppNetworkImage(url: item.imageUrl, width: 56, height: 56, borderRadius: BorderRadius.circular(10)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${item.distanceKm.toStringAsFixed(1)} km away', style: Theme.of(context).textTheme.bodySmall),
                      if (item.rating != null) RatingBadge(rating: item.rating!),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmergencyContactTile extends StatelessWidget {
  final EmergencyContact contact;
  const _EmergencyContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_phone_outlined, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(contact.phoneNumber, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            TextButton(
              onPressed: () => launchUrl(Uri.parse('tel:${contact.phoneNumber}')),
              child: const Text('Call'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final PlaceReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(review.userName.isNotEmpty ? review.userName[0] : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(review.userName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    RatingBadge(rating: review.rating),
                  ],
                ),
                const SizedBox(height: 4),
                Text(review.comment, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
