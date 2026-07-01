import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../providers/groups_provider.dart';
import '../../widgets/common/ui_atoms.dart';

/// "My Travel Groups" — reached from the Profile menu. Shows every group
/// the signed-in user created, joined, or has a pending request on.
class MyGroupsScreen extends ConsumerWidget {
  const MyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Travel Groups')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load your groups.')),
        data: (groups) {
          if (groups.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              title: 'No groups yet',
              subtitle: 'Open any destination and tap "Travelers Planning This Trip" to join or start a group.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, 32),
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
}
