import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/division_model.dart';
import '../../providers/guide_provider.dart';
import '../../widgets/common/app_network_image.dart';
import 'district_list_screen.dart';

/// Top of the Travel Guide hierarchy: Division -> District -> TouristPlace.
/// Shows all 8 divisions of Bangladesh as large, tappable cards.
class DivisionListScreen extends ConsumerWidget {
  const DivisionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final divisionsAsync = ref.watch(divisionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Travel Guide')),
      body: divisionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load the travel guide. Pull to retry.')),
        data: (divisions) => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: divisions.length,
          itemBuilder: (context, i) => _DivisionTile(division: divisions[i]),
        ),
      ),
    );
  }
}

class _DivisionTile extends StatelessWidget {
  final Division division;
  const _DivisionTile({required this.division});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DistrictListScreen(division: division)),
        ),
        child: Container(
          height: 140,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            children: [
              Positioned.fill(
                child: AppNetworkImage(url: division.imageUrl, borderRadius: BorderRadius.circular(20)),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.65), Colors.black.withOpacity(0.05)],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      division.name,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${division.districtIds.length} districts',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
