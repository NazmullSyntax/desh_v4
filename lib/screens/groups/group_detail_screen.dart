import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/travel_group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/groups_provider.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/primary_button.dart';
import 'group_chat_screen.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupByIdProvider(groupId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load this group.')),
        data: (group) {
          if (group == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('This group no longer exists.')),
            );
          }
          final uid = currentUser?.uid;
          final isMember = uid != null && group.isMember(uid);
          final isOwner = uid != null && group.isOwner(uid);
          final isPending = uid != null && group.hasPendingRequest(uid);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: AppNetworkImage(url: group.coverImage, fit: BoxFit.cover),
                  title: Text(group.destinationName, style: const TextStyle(fontSize: 14, shadows: [Shadow(blurRadius: 6)])),
                ),
                actions: [
                  if (isMember)
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      tooltip: 'Group Chat',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: group.id, groupTitle: group.title)),
                      ),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.title, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text('Created by ${group.members.isNotEmpty ? group.members.first.name : 'a traveler'}', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.lg),
                      _StatsRow(group: group),
                      const SizedBox(height: AppSpacing.lg),
                      if (group.description.isNotEmpty) ...[
                        Text('About this trip', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(group.description, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Members (${group.members.length}/${group.maxMembers})', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...group.members.map((m) => _MemberTile(member: m, isOwner: group.isOwner(m.uid))),
                      if (isOwner && group.pendingRequests.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text('Join requests (${group.pendingRequests.length})', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...group.pendingRequests.map((m) => _PendingRequestTile(groupId: group.id, member: m)),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _ActionButton(group: group, isMember: isMember, isOwner: isOwner, isPending: isPending, currentUid: uid),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final TravelGroup group;
  const _StatsRow({required this.group});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatTile(icon: Icons.calendar_today_outlined, label: 'Date', value: DateFormat('d MMM yyyy').format(group.tripDate))),
        Expanded(child: _StatTile(icon: Icons.account_balance_wallet_outlined, label: 'Budget', value: formatBDT(group.budgetBdt))),
        Expanded(child: _StatTile(icon: Icons.event_seat_outlined, label: 'Seats left', value: '${group.remainingSeats}')),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final GroupMemberProfile member;
  final bool isOwner;
  const _MemberTile({required this.member, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final initial = member.name.trim().isNotEmpty ? member.name.trim()[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: AppColors.primary, child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Expanded(child: Text(member.name)),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
              child: const Text('Organizer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accentDark)),
            ),
        ],
      ),
    );
  }
}

class _PendingRequestTile extends ConsumerWidget {
  final String groupId;
  final GroupMemberProfile member;
  const _PendingRequestTile({required this.groupId, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(groupsActionsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(radius: 16, backgroundColor: AppColors.textSecondaryLight, child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 12))),
          const SizedBox(width: 12),
          Expanded(child: Text(member.name)),
          IconButton(
            icon: const Icon(Icons.check_circle, color: AppColors.primary),
            onPressed: () => actions.approveRequest(groupId, member.uid),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: AppColors.error),
            onPressed: () => actions.rejectRequest(groupId, member.uid),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends ConsumerWidget {
  final TravelGroup group;
  final bool isMember;
  final bool isOwner;
  final bool isPending;
  final String? currentUid;

  const _ActionButton({
    required this.group,
    required this.isMember,
    required this.isOwner,
    required this.isPending,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(groupsActionsProvider);

    if (currentUid == null) {
      return const PrimaryButton(label: 'Sign in to join', onPressed: null);
    }
    if (isOwner) {
      return PrimaryButton(
        label: 'Open Group Chat',
        icon: Icons.chat_bubble_outline,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: group.id, groupTitle: group.title)),
        ),
      );
    }
    if (isMember) {
      return PrimaryButton(
        label: 'Leave Group',
        color: AppColors.error,
        icon: Icons.logout_rounded,
        onPressed: () => actions.leaveGroup(group.id),
      );
    }
    if (isPending) {
      return const PrimaryButton(label: 'Request sent \u00b7 awaiting approval', onPressed: null, icon: Icons.hourglass_top_rounded);
    }
    if (group.isFull) {
      return const PrimaryButton(label: 'Group is full', onPressed: null);
    }
    return PrimaryButton(
      label: group.isRequestApprovalRequired ? 'Request to Join' : 'Join Group',
      icon: Icons.group_add_rounded,
      onPressed: () => actions.joinOrRequest(group),
    );
  }
}
