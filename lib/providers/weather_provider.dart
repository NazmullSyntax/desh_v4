import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../models/weather_model.dart';

/// Mock weather data source. Replace with a real OpenWeatherMap / WeatherAPI
/// Dio call (see core for the shared Dio client) once an API key is
/// available — [WeatherInfo] / [DailyForecast] models stay the same.
final weatherProvider = FutureProvider.family<WeatherInfo, String>((ref, locationName) async {
  await Future.delayed(const Duration(milliseconds: 500));

  final random = Random(locationName.hashCode);
  final baseTemp = 24 + random.nextInt(10);

  final conditions = ['Sunny', 'Partly Cloudy', 'Cloudy', 'Light Rain'];
  final icons = ['sunny', 'partly_cloudy', 'cloudy', 'rain'];

  final forecast = List.generate(7, (i) {
    final conditionIndex = random.nextInt(conditions.length);
    return DailyForecast(
      date: DateTime.now().add(Duration(days: i)),
      maxTempC: (baseTemp + random.nextInt(4)).toDouble(),
      minTempC: (baseTemp - random.nextInt(5)).toDouble(),
      rainProbability: random.nextInt(100),
      condition: conditions[conditionIndex],
      icon: icons[conditionIndex],
    );
  });

  return WeatherInfo(
    locationName: locationName,
    currentTempC: baseTemp.toDouble(),
    condition: conditions[random.nextInt(conditions.length)],
    icon: icons[random.nextInt(icons.length)],
    humidity: 55 + random.nextInt(35),
    windSpeedKmh: 5 + random.nextInt(20).toDouble(),
    rainProbability: random.nextInt(80),
    forecast: forecast,
  );
});

/// Currently selected location for the Weather module / home weather card.
final weatherLocationProvider = StateProvider<String>((ref) => "Cox's Bazar");
