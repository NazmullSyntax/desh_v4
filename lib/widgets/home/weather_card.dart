import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/weather_provider.dart';

IconData _weatherIcon(String icon) {
  switch (icon) {
    case 'sunny':
      return Icons.wb_sunny_rounded;
    case 'partly_cloudy':
      return Icons.wb_cloudy_rounded;
    case 'cloudy':
      return Icons.cloud_rounded;
    case 'rain':
      return Icons.water_drop_rounded;
    default:
      return Icons.wb_sunny_rounded;
  }
}

/// Glassmorphism-styled weather summary card shown near the top of Home.
class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(weatherLocationProvider);
    final weatherAsync = ref.watch(weatherProvider(location));

    return GestureDetector(
      onTap: () => context.push(AppRoutes.weather),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.skyGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: weatherAsync.when(
          loading: () => const SizedBox(height: 64, child: Center(child: CircularProgressIndicator(color: Colors.white))),
          error: (e, st) => const SizedBox(height: 64, child: Center(child: Text('Weather unavailable', style: TextStyle(color: Colors.white)))),
          data: (weather) {
            return Row(
              children: [
                Icon(_weatherIcon(weather.icon), color: Colors.white, size: 44),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.locationName,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        weather.condition,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${weather.currentTempC.round()}°C',
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
