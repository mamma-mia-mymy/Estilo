import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/weather_service.dart';

/// Caches weather data with timestamp
class WeatherCache {
  final WeatherData data;
  final DateTime fetchedAt;

  WeatherCache({required this.data, required this.fetchedAt});

  bool get isExpired {
    final now = DateTime.now();
    final age = now.difference(fetchedAt);
    return age.inHours >= 1; // Refresh after 1 hour
  }
}

class WeatherNotifier extends StateNotifier<AsyncValue<WeatherData?>> {
  WeatherNotifier() : super(const AsyncValue.loading());

  WeatherCache? _cache;

  Future<void> fetchWeatherByLocation() async {
    try {
      state = const AsyncValue.loading();

      // Check cache first
      if (_cache != null && !_cache!.isExpired) {
        state = AsyncValue.data(_cache!.data);
        return;
      }

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        state = const AsyncValue.data(null);
        return;
      }
      
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        state = const AsyncValue.data(null);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Fetch weather data
      final weatherData = await WeatherService.fetchWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Cache the result
      if (weatherData != null) {
        _cache = WeatherCache(
          data: weatherData,
          fetchedAt: DateTime.now(),
        );
      }

      state = AsyncValue.data(weatherData);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> fetchWeatherByCity(String cityName) async {
    try {
      state = const AsyncValue.loading();

      // Check cache first
      if (_cache != null && !_cache!.isExpired) {
        state = AsyncValue.data(_cache!.data);
        return;
      }

      final weatherData = await WeatherService.fetchWeatherByCity(cityName);

      // Cache the result
      if (weatherData != null) {
        _cache = WeatherCache(
          data: weatherData,
          fetchedAt: DateTime.now(),
        );
      }

      state = AsyncValue.data(weatherData);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearCache() {
    _cache = null;
  }
}

final weatherProvider =
    StateNotifierProvider<WeatherNotifier, AsyncValue<WeatherData?>>(
  (ref) => WeatherNotifier(),
);
