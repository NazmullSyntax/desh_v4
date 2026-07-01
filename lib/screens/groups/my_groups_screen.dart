import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/groups_provider.dart';
import '../../providers/guide_provider.dart';
import '../groups/groups_for_place_screen.dart';

/// "My Travel Groups" — reached from the Profile menu. Shows every group
/// the signed-in user created, joined, or has a pending request on.
class MyGroupsScreen extends ConsumerWidget {
  const MyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Travel Groups')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBrowseDialog(context, ref),
        icon: const Icon(Icons.search_rounded),
        label: const Text('Find & Join'),
        backgroundColor: AppColors.primary,
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load your groups.')),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.groups_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 24),
                    Text(
                      'No groups yet',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create your own trip or browse destinations to join existing groups',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _showBrowseDialog(context, ref),
                        icon: const Icon(Icons.explore_rounded),
                        label: const Text('Browse Destinations & Find Groups', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        onPressed: () => context.go(AppRoutes.guide),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create a New Trip', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, 96),
            itemCount: groups.length,
            separatorBuilder: (context, i) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final g = groups[i];
              return ListTile(
                tileColor: Theme.of(context).cardTheme.color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: Text(g.title),
                subtitle: Text('${g.destinationName} \u00b7 ${g.members.length}/${g.maxMembers} going'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('${AppRoutes.groupDetail}?id=${g.id}'),
              );
            },
          );
        },
      ),
    );
  }

  void _showBrowseDialog(BuildContext context, WidgetRef ref) {
    final allPlacesAsync = ref.read(allTouristPlacesProvider);
    
    allPlacesAsync.whenData((places) {
      if (places.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No destinations available')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Select a Destination'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: places.length,
              itemBuilder: (context, i) {
                final place = places[i];
                return ListTile(
                  title: Text(place.name),
                  subtitle: Text(place.banglaName),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupsForPlaceScreen(
                          placeId: place.id,
                          destinationName: place.name,
                          coverImage: place.imageUrls.isNotEmpty ? place.imageUrls.first : place.coverImage,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    });
  }
}
