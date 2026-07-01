import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/division_model.dart';
import '../../screens/guide/district_list_screen.dart';
import '../common/app_network_image.dart';

class _Category {
  final String label;
  final IconData icon;
  const _Category(this.label, this.icon);
}

const _categories = [
  _Category('Beaches', Icons.beach_access_outlined),
  _Category('Hills', Icons.terrain_outlined),
  _Category('Heritage', Icons.account_balance_outlined),
  _Category('Wildlife', Icons.pets_outlined),
  _Category('Tea Gardens', Icons.local_florist_outlined),
  _Category('Rivers', Icons.water_outlined),
];

/// Horizontal scrollable row of category filter chips (Beaches, Hills,
/// Heritage, etc) shown on the Home screen.
class CategoryChipRow extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const CategoryChipRow({super.key, this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, i) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final isSelected = selected == cat.label;
          return GestureDetector(
            onTap: () => onSelect(isSelected ? null : cat.label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primary : Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Icon(cat.icon, size: 16, color: isSelected ? Colors.white : Theme.of(context).iconTheme.color),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Card representing a division in the "Explore by Division" section.
class DivisionCard extends StatelessWidget {
  final Division division;
  const DivisionCard({super.key, required this.division});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DistrictListScreen(division: division)),
      ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Stack(
          children: [
            AppNetworkImage(
              url: division.imageUrl,
              width: 140,
              height: 90,
              borderRadius: BorderRadius.circular(16),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Text(
                division.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
