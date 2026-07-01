import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/travel_group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/groups_provider.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/ui_atoms.dart';
import 'create_group_screen.dart';

/// Browse all open travel groups heading to one destination — reached from
/// the "Travelers Planning This Trip" section on the place detail screen.
class GroupsForPlaceScreen extends ConsumerWidget {
  final String placeId;
  final String destinationName;
  final String coverImage;

  const GroupsForPlaceScreen({
    super.key,
    required this.placeId,
    required this.destinationName,
    required this.coverImage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsForPlaceProvider(placeId));

    return Scaffold(
      appBar: AppBar(title: Text('Groups \u00b7 $destinationName')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateGroupScreen(
              placeId: placeId,
              destinationName: destinationName,
              coverImage: coverImage,
            ),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Group'),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load groups.')),
        data: (groups) {
          if (groups.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              title: 'No groups yet',
              subtitle: 'Be the first to start a group trip here \u2014 tap "Create Group" below.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, 96),
            itemCount: groups.length,
            separatorBuilder: (context, i) => const SizedBox(height: 14),
            itemBuilder: (context, i) => _GroupCard(group: groups[i]),
          );
        },
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final TravelGroup group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isMember = currentUser != null && group.isMember(currentUser.uid);
    final isPending = currentUser != null && group.hasPendingRequest(currentUser.uid);
    final canJoin = currentUser != null && !isMember && !isPending && !group.isFull;

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.groupDetail}?id=${group.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AppNetworkImage(url: group.coverImage, width: 56, height: 56, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('d MMM yyyy').format(group.tripDate),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isMember)
                  const _StatusChip(label: 'Joined', color: AppColors.primary)
                else if (isPending)
                  const _StatusChip(label: 'Requested', color: AppColors.accentDark)
                else if (group.isFull)
                  const _StatusChip(label: 'Full', color: AppColors.error),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoPill(icon: Icons.groups_outlined, label: '${group.members.length}/${group.maxMembers} going'),
                const SizedBox(width: 8),
                _InfoPill(icon: Icons.account_balance_wallet_outlined, label: formatBDT(group.budgetBdt)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 15, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Meet at ${group.meetingPoint}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AvatarStack(members: group.members),
            if (canJoin) ...[
              const SizedBox(height: 12),
              _JoinButton(group: group),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.secondaryDark),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.secondaryDark)),
        ],
      ),
    );
  }
}

/// Shared avatar-stack widget: overlapping circular initials for the first
/// few members, plus a "+N" badge for the rest.
class _AvatarStack extends StatelessWidget {
  final List<GroupMemberProfile> members;
  const _AvatarStack({required this.members});

  @override
  Widget build(BuildContext context) {
    const maxShown = 4;
    final shown = members.take(maxShown).toList();
    final extra = members.length - shown.length;

    return SizedBox(
      height: 30,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * 20.0,
              child: _InitialAvatar(name: shown[i].name),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * 20.0,
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textSecondaryLight,
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                ),
                child: Text('+$extra', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;
  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
      ),
      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _JoinButton extends ConsumerStatefulWidget {
  final TravelGroup group;
  const _JoinButton({required this.group});

  @override
  ConsumerState<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends ConsumerState<_JoinButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: _isLoading
            ? null
            : () async {
                final messenger = ScaffoldMessenger.of(context);
                setState(() => _isLoading = true);
                try {
                  await ref.read(groupsActionsProvider).joinOrRequest(widget.group);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.group.isRequestApprovalRequired
                            ? 'Request sent! Waiting for organizer approval.'
                            : 'You joined the group!',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
        icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : const Icon(Icons.group_add_rounded, size: 18),
        label: Text(_isLoading ? 'Joining...' : (widget.group.isRequestApprovalRequired ? 'Request to Join' : 'Join Group')),
      ),
    );
  }
}
