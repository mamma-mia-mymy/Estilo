import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // OpenWeather API key — get free at openweathermap.org
  static const String _apiKey = 'bcd20d9bbd409b5d59cc47d846220fa2';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  /// Fetch current weather by coordinates (latitude, longitude)
  static Future<WeatherData?> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?lat=$latitude&lon=$longitude&units=metric&appid=$_apiKey',
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return WeatherData.fromJson(json);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch current weather by city name
  static Future<WeatherData?> fetchWeatherByCity(String cityName) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$cityName&units=metric&appid=$_apiKey',
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return WeatherData.fromJson(json);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class WeatherData {
  final double temperature;
  final String condition;
  final String description;
  final String cityName;
  final String country;
  final int humidity;
  final double windSpeed;

  const WeatherData({
    required this.temperature,
    required this.condition,
    required this.description,
    required this.cityName,
    required this.country,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;
    final sys = json['sys'] as Map<String, dynamic>;

    return WeatherData(
      temperature: (main['temp'] as num).toDouble(),
      condition: weather['main'] as String,
      description: weather['description'] as String,
      cityName: json['name'] as String,
      country: sys['country'] as String,
      humidity: main['humidity'] as int,
      windSpeed: (wind['speed'] as num).toDouble(),
    );
  }

  /// Returns a user-friendly temperature display
  String get temperatureDisplay => '${temperature.toStringAsFixed(0)}°C';

  /// Returns weather advice based on temperature
  String get weatherAdvice {
    if (temperature >= 30) {
      return 'Light layers recommended';
    } else if (temperature >= 20) {
      return 'Comfortable weather';
    } else if (temperature >= 10) {
      return 'Layering advised';
    } else {
      return 'Warm clothes needed';
    }
  }
}
