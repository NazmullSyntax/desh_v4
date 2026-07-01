/// One day within a 7-day forecast.
class DailyForecast {
  final DateTime date;
  final double maxTempC;
  final double minTempC;
  final int rainProbability; // percentage 0-100
  final String condition; // e.g. "Sunny", "Cloudy", "Light Rain"
  final String icon; // maps to a weather icon key

  const DailyForecast({
    required this.date,
    required this.maxTempC,
    required this.minTempC,
    required this.rainProbability,
    required this.condition,
    required this.icon,
  });
}

/// Current weather snapshot + 7-day forecast for a given location.
class WeatherInfo {
  final String locationName;
  final double currentTempC;
  final String condition;
  final String icon;
  final int humidity; // percentage
  final double windSpeedKmh;
  final int rainProbability;
  final List<DailyForecast> forecast;

  const WeatherInfo({
    required this.locationName,
    required this.currentTempC,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.windSpeedKmh,
    required this.rainProbability,
    required this.forecast,
  });
}
