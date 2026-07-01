import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../models/weather_model.dart';
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

/// Full Weather module screen: current conditions + 7-day forecast for the
/// selected location. Reached from the Home weather card.
class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(weatherLocationProvider);
    final weatherAsync = ref.watch(weatherProvider(location));

    return Scaffold(
      appBar: AppBar(title: const Text('Weather')),
      body: weatherAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load weather data.')),
        data: (weather) => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            _CurrentWeatherCard(weather: weather),
            const SizedBox(height: 24),
            Text('7-Day Forecast', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...weather.forecast.map((day) => _ForecastTile(day: day)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _CurrentWeatherCard extends StatelessWidget {
  final WeatherInfo weather;
  const _CurrentWeatherCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: AppColors.skyGradient, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Text(weather.locationName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Icon(_weatherIcon(weather.icon), color: Colors.white, size: 64),
          const SizedBox(height: 8),
          Text('${weather.currentTempC.round()}°C', style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w700)),
          Text(weather.condition, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(icon: Icons.water_drop_outlined, label: 'Humidity', value: '${weather.humidity}%'),
              _StatColumn(icon: Icons.air, label: 'Wind', value: '${weather.windSpeedKmh.round()} km/h'),
              _StatColumn(icon: Icons.umbrella_outlined, label: 'Rain', value: '${weather.rainProbability}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatColumn({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
      ],
    );
  }
}

class _ForecastTile extends StatelessWidget {
  final DailyForecast day;
  const _ForecastTile({required this.day});

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat('EEEE').format(day.date);
    final dateLabel = DateFormat('MMM d').format(day.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dayLabel, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Icon(_weatherIcon(day.icon), color: AppColors.secondary, size: 24),
          const SizedBox(width: 10),
          Expanded(child: Text(day.condition, style: Theme.of(context).textTheme.bodySmall)),
          Row(
            children: [
              const Icon(Icons.water_drop_outlined, size: 14, color: AppColors.secondary),
              const SizedBox(width: 2),
              Text('${day.rainProbability}%', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(width: 14),
          Text(
            '${day.maxTempC.round()}° / ${day.minTempC.round()}°',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
