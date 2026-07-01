import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../models/division_model.dart';
import '../../providers/guide_provider.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/ui_atoms.dart';

/// Shows every district within a [Division]. Districts with curated rich
/// data are tappable straight into the detail screen; districts without
/// rich data yet show a "Coming soon" badge but remain visible, so the
/// full administrative map of Bangladesh is represented even before every
/// district has content.
class DistrictListScreen extends ConsumerWidget {
  final Division division;
  const DistrictListScreen({super.key, required this.division});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final districtsAsync = ref.watch(districtsForDivisionProvider(division.id));

    return Scaffold(
      appBar: AppBar(title: Text(division.name)),
      body: districtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load districts.')),
        data: (districts) {
          if (districts.isEmpty) {
            return const EmptyState(
              icon: Icons.map_outlined,
              title: 'No districts yet',
              subtitle: 'District data for this division is coming soon.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: districts.length,
            separatorBuilder: (context, i) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _DistrictTile(district: districts[i]),
          );
        },
      ),
    );
  }
}

class _DistrictTile extends StatelessWidget {
  final District district;
  const _DistrictTile({required this.district});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: district.hasRichData ? 1 : 0.6,
      child: GestureDetector(
        onTap: () {
          if (district.hasRichData) {
            context.push('${AppRoutes.districtDetail}?id=${district.id}');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${district.name} guide is coming soon!')),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              AppNetworkImage(
                url: district.imageUrl,
                width: 64,
                height: 64,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(district.name, style: Theme.of(context).textTheme.titleMedium),
                    Text(district.banglaName, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (!district.hasRichData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Soon', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                )
              else
                const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
