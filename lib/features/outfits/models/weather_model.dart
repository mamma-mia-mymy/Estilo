class WeatherModel {
  final double temperature;
  final String condition;
  final String description;
  final double humidity;
  final double windSpeed;
  final String cityName;
  final String country;
  final DateTime timestamp;

  const WeatherModel({
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.cityName,
    required this.country,
    required this.timestamp,
  });

  factory WeatherModel.fromOpenWeather(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;
    final sys = json['sys'] as Map<String, dynamic>;

    return WeatherModel(
      temperature: (main['temp'] as num).toDouble(),
      condition: weather['main'] as String,
      description: weather['description'] as String,
      humidity: (main['humidity'] as num).toDouble(),
      windSpeed: (wind['speed'] as num).toDouble(),
      cityName: json['name'] as String,
      country: sys['country'] as String,
      timestamp: DateTime.now(),
    );
  }

  factory WeatherModel.placeholder() {
    return WeatherModel(
      temperature: 28.0,
      condition: 'Clear',
      description: 'clear sky',
      humidity: 65.0,
      windSpeed: 3.5,
      cityName: 'Dasmariñas',
      country: 'PH',
      timestamp: DateTime.now(),
    );
  }

  bool get isHot => temperature >= 25;
  bool get isWarm => temperature >= 18 && temperature < 25;
  bool get isCool => temperature >= 10 && temperature < 18;
  bool get isCold => temperature < 10;

  bool get isRainy {
    final conditionLower = condition.toLowerCase();
    return conditionLower.contains('rain') ||
        conditionLower.contains('drizzle') ||
        conditionLower.contains('thunderstorm');
  }

  bool get isSunny {
    final conditionLower = condition.toLowerCase();
    return conditionLower.contains('clear') || conditionLower.contains('sunny');
  }

  bool get isCloudy {
    final conditionLower = condition.toLowerCase();
    return conditionLower.contains('cloud') || conditionLower.contains('overcast');
  }

  String get temperatureDisplay => '${temperature.round()}°';

  String get weatherAdvice {
    if (isHot) {
      return 'GOOD DAY FOR LIGHT LAYERS';
    } else if (isWarm) {
      return 'PERFECT FOR CASUAL WEAR';
    } else if (isCool) {
      return 'CONSIDER LAYERING';
    } else {
      return 'OPT FOR WARM LAYERS';
    }
  }

  WeatherModel copyWith({
    double? temperature,
    String? condition,
    String? description,
    double? humidity,
    double? windSpeed,
    String? cityName,
    String? country,
    DateTime? timestamp,
  }) {
    return WeatherModel(
      temperature: temperature ?? this.temperature,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      cityName: cityName ?? this.cityName,
      country: country ?? this.country,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
