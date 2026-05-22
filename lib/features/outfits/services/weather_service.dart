import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';

class WeatherService {
  // OpenWeather API key - replace with actual key from environment/config
  static const String _apiKey = 'YOUR_OPENWEATHER_API_KEY';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  WeatherModel? _cachedWeather;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permission
      var permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get weather by coordinates
  Future<WeatherModel?> getWeatherByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    // Check cache first
    if (_cachedWeather != null && _lastFetchTime != null) {
      final elapsed = DateTime.now().difference(_lastFetchTime!);
      if (elapsed < _cacheDuration) {
        return _cachedWeather;
      }
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedWeather = WeatherModel.fromOpenWeather(json);
        _lastFetchTime = DateTime.now();
        return _cachedWeather;
      }
    } catch (e) {
      // Return cached or placeholder on error
      return _cachedWeather ?? WeatherModel.placeholder();
    }

    return _cachedWeather ?? WeatherModel.placeholder();
  }

  /// Get weather by city name
  Future<WeatherModel?> getWeatherByCity(String cityName) async {
    // Check cache first
    if (_cachedWeather != null && _lastFetchTime != null) {
      final elapsed = DateTime.now().difference(_lastFetchTime!);
      if (elapsed < _cacheDuration && _cachedWeather!.cityName.toLowerCase() == cityName.toLowerCase()) {
        return _cachedWeather;
      }
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedWeather = WeatherModel.fromOpenWeather(json);
        _lastFetchTime = DateTime.now();
        return _cachedWeather;
      }
    } catch (e) {
      return _cachedWeather ?? WeatherModel.placeholder();
    }

    return _cachedWeather ?? WeatherModel.placeholder();
  }

  /// Get weather for current location
  Future<WeatherModel?> getWeatherForCurrentLocation() async {
    final position = await getCurrentPosition();
    if (position == null) {
      return WeatherModel.placeholder();
    }

    return getWeatherByCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Get cached weather (or placeholder)
  WeatherModel getCachedWeather() {
    return _cachedWeather ?? WeatherModel.placeholder();
  }

  /// Clear cache
  void clearCache() {
    _cachedWeather = null;
    _lastFetchTime = null;
  }

  /// Check if cache is valid
  bool isCacheValid() {
    if (_cachedWeather == null || _lastFetchTime == null) return false;
    final elapsed = DateTime.now().difference(_lastFetchTime!);
    return elapsed < _cacheDuration;
  }
}
