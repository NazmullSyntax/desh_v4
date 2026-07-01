import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/tourist_place_model.dart';

/// Map & Navigation screen for a single tourist place.
///
/// IMPORTANT: This build renders a static placeholder map (no API key
/// configured in this sandbox) with working "Open in Google Maps" /
/// "Get Directions" actions via [url_launcher]. To show a live interactive
/// map, add a Google Maps API key (see SETUP_INSTRUCTIONS.md) and replace
/// the `_MapPlaceholder` widget below with a `GoogleMap` widget — the
/// `google_maps_flutter` package is already a dependency and the
/// lat/lng/markers logic here translates directly.
class PlaceMapScreen extends StatelessWidget {
  final TouristPlace place;
  const PlaceMapScreen({super.key, required this.place});

  Future<void> _openInGoogleMaps() async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _getDirections() async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final nearbyServices = [
      ('Hotels', Icons.hotel_outlined, AppColors.secondary),
      ('Restaurants', Icons.restaurant_outlined, AppColors.accent),
      ('Hospitals', Icons.local_hospital_outlined, AppColors.error),
      ('Police', Icons.local_police_outlined, AppColors.primary),
      ('ATMs', Icons.atm_outlined, AppColors.secondaryDark),
      ('Petrol Pumps', Icons.local_gas_station_outlined, AppColors.accentDark),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(place.name)),
      body: Column(
        children: [
          Expanded(child: _MapPlaceholder(place: place)),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openInGoogleMaps,
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Open in Maps'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _getDirections,
                          icon: const Icon(Icons.directions_outlined, size: 18),
                          label: const Text('Directions'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Nearby Services', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: nearbyServices.length,
                      separatorBuilder: (context, i) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final (label, icon, color) = nearbyServices[i];
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(height: 6),
                            Text(label, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final TouristPlace place;
  const _MapPlaceholder({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.06),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Faux grid lines to suggest a map without needing tiles/API key.
          CustomPaint(size: Size.infinite, painter: _GridPainter()),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: AppColors.error, size: 48),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                child: Text(place.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              ),
              const SizedBox(height: 16),
              Text(
                '${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.08)
      ..strokeWidth = 1;
    const gap = 32.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
