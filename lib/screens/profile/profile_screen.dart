import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hotel_provider.dart' show favoritesProvider;
import '../../providers/trip_planner_provider.dart';
import '../../widgets/common/app_network_image.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final favorites = ref.watch(favoritesProvider);
    final trips = ref.watch(savedTripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(onPressed: () => context.push(AppRoutes.settings), icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => context.push(AppRoutes.editProfile),
                  child: Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.15),
                        ),
                        child: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                            ? ClipOval(child: AppNetworkImage(url: user.photoUrl!, width: 88, height: 88))
                            : Center(
                                child: Text(
                                  (user?.displayName.isNotEmpty ?? false) ? user!.displayName[0].toUpperCase() : 'T',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.displayName ?? 'Traveler', style: Theme.of(context).textTheme.titleLarge),
                if (user?.email != null) Text(user!.email!, style: Theme.of(context).textTheme.bodySmall),
                if (user?.isGuest ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.register),
                      child: const Text('Create an account to save your trips'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _StatCard(icon: Icons.card_travel, label: 'Trips', value: '${trips.length}')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(icon: Icons.favorite_outline, label: 'Favorites', value: '${favorites.length}')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(icon: Icons.place_outlined, label: 'Visited', value: '${user?.placesVisited ?? 0}')),
            ],
          ),
          const SizedBox(height: 28),

          Text('Achievement Badges', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const _BadgeRow(),

          const SizedBox(height: 28),
          _ProfileMenuTile(icon: Icons.edit_outlined, label: 'Edit Profile', onTap: () => context.push(AppRoutes.editProfile)),
          _ProfileMenuTile(icon: Icons.receipt_long_outlined, label: 'My Bookings', onTap: () => context.push(AppRoutes.bookings)),
          _ProfileMenuTile(icon: Icons.groups_outlined, label: 'My Travel Groups', onTap: () => context.push(AppRoutes.myGroups)),
          _ProfileMenuTile(icon: Icons.card_travel_outlined, label: 'Saved Trips', subtitle: '${trips.length} trips planned', onTap: () {}),
          _ProfileMenuTile(icon: Icons.favorite_border, label: 'Favorite Places', subtitle: '${favorites.length} saved', onTap: () => context.push(AppRoutes.favorites)),
          _ProfileMenuTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => context.push(AppRoutes.notifications)),
          _ProfileMenuTile(icon: Icons.shield_outlined, label: 'Safety Center', onTap: () => context.push(AppRoutes.safety)),
          _ProfileMenuTile(icon: Icons.settings_outlined, label: 'Settings', onTap: () => context.push(AppRoutes.settings)),
          _ProfileMenuTile(icon: Icons.help_outline, label: 'Help Center', onTap: () {}),

          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Log Out', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                try {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out successfully'), duration: Duration(seconds: 2)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error logging out: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text('Log Out', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error), minimumSize: const Size.fromHeight(54)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}


class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow();

  static const _badges = [
    ('First Trip', Icons.flight_takeoff, true),
    ('Explorer', Icons.explore, true),
    ('Beach Lover', Icons.beach_access, false),
    ('Hill Hiker', Icons.terrain, false),
    ('Foodie', Icons.restaurant, false),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _badges.length,
        separatorBuilder: (context, i) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final (label, icon, unlocked) = _badges[i];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: unlocked ? AppColors.accent.withOpacity(0.15) : Theme.of(context).dividerColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: unlocked ? AppColors.accentDark : Theme.of(context).textTheme.bodySmall?.color, size: 26),
              ),
              const SizedBox(height: 6),
              Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  const _ProfileMenuTile({required this.icon, required this.label, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
