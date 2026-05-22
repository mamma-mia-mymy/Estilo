import '../models/wardrobe_item_model.dart';
import '../models/outfit_model.dart';
import '../models/weather_model.dart';
import 'color_compatibility_service.dart';

class OutfitScorerService {
  final ColorCompatibilityService _colorService;

  OutfitScorerService({ColorCompatibilityService? colorService})
      : _colorService = colorService ?? ColorCompatibilityService();

  /// Calculate complete outfit score
  /// Uses weighted formula: (colorHarmony * 0.25) + (styleConsistency * 0.25) +
  /// (formalityAlignment * 0.20) + (weatherCompatibility * 0.15) +
  /// (userPreferenceMatch * 0.15)
  OutfitScoreBreakdown calculateScore({
    required WardrobeItemModel top,
    required WardrobeItemModel bottom,
    WeatherModel? weather,
    List<String>? userPreferredStyles,
    List<String>? userPreferredColors,
    String? userSkinTone,
  }) {
    // Color Harmony (25%)
    final colorHarmony = _calculateColorHarmony(
      topColor: top.color,
      bottomColor: bottom.color,
      userSkinTone: userSkinTone,
    );

    // Style Consistency (25%)
    final styleConsistency = _calculateStyleConsistency(
      topStyle: top.style,
      bottomStyle: bottom.style,
    );

    // Formality Alignment (20%)
    final formalityAlignment = _calculateFormalityAlignment(
      topStyle: top.style,
      bottomStyle: bottom.style,
    );

    // Weather Compatibility (15%)
    final weatherCompatibility = _calculateWeatherCompatibility(
      top: top,
      bottom: bottom,
      weather: weather,
    );

    // User Preference Match (15%)
    final userPreferenceMatch = _calculateUserPreferenceMatch(
      top: top,
      bottom: bottom,
      preferredStyles: userPreferredStyles,
      preferredColors: userPreferredColors,
    );

    return OutfitScoreBreakdown(
      colorHarmony: colorHarmony,
      styleConsistency: styleConsistency,
      formalityAlignment: formalityAlignment,
      weatherCompatibility: weatherCompatibility,
      userPreferenceMatch: userPreferenceMatch,
    );
  }

  /// Color Harmony Score (0.0 - 1.0)
  double _calculateColorHarmony({
    required String topColor,
    required String bottomColor,
    String? userSkinTone,
  }) {
    final baseScore = _colorService.getColorCompatibilityScore(topColor, bottomColor);

    // Apply skin tone adjustment if available
    if (userSkinTone != null && userSkinTone.isNotEmpty) {
      final topSkinScore =
          _colorService.getSkinToneCompatibilityScore(
        clothingColor: topColor,
        userSkinTone: userSkinTone,
      );
      final bottomSkinScore =
          _colorService.getSkinToneCompatibilityScore(
        clothingColor: bottomColor,
        userSkinTone: userSkinTone,
      );
      final skinToneBonus = (topSkinScore + bottomSkinScore) / 2;

      // Blend base score with skin tone score
      return (baseScore * 0.7) + (skinToneBonus * 0.3);
    }

    return baseScore;
  }

  /// Style Consistency Score (0.0 - 1.0)
  /// Same styles get high score, conflicting styles get low score
  double _calculateStyleConsistency({
    required WardrobeStyle topStyle,
    required WardrobeStyle bottomStyle,
  }) {
    if (topStyle == bottomStyle) {
      return 0.95; // Perfect match
    }

    // Define style compatibility groups
    final compatibleStyles = {
      WardrobeStyle.casual: {
        WardrobeStyle.casual,
        WardrobeStyle.streetwear,
      },
      WardrobeStyle.formal: {
        WardrobeStyle.formal,
        WardrobeStyle.minimalist,
      },
      WardrobeStyle.vintage: {
        WardrobeStyle.vintage,
        WardrobeStyle.casual,
      },
      WardrobeStyle.streetwear: {
        WardrobeStyle.streetwear,
        WardrobeStyle.casual,
      },
      WardrobeStyle.minimalist: {
        WardrobeStyle.minimalist,
        WardrobeStyle.formal,
        WardrobeStyle.casual,
      },
    };

    // Check if styles are compatible
    final topCompatible = compatibleStyles[topStyle] ?? {};
    if (topCompatible.contains(bottomStyle)) {
      return 0.7;
    }

    // Conflicting styles
    final conflictingStyles = {
      WardrobeStyle.formal: {
        WardrobeStyle.streetwear,
        WardrobeStyle.vintage,
      },
      WardrobeStyle.streetwear: {
        WardrobeStyle.formal,
      },
      WardrobeStyle.vintage: {
        WardrobeStyle.formal,
      },
    };

    final topConflicting = conflictingStyles[topStyle] ?? {};
    if (topConflicting.contains(bottomStyle)) {
      return 0.2;
    }

    // Default - moderate mismatch
    return 0.5;
  }

  /// Formality Alignment Score (0.0 - 1.0)
  /// Use formality values to calculate variance
  double _calculateFormalityAlignment({
    required WardrobeStyle topStyle,
    required WardrobeStyle bottomStyle,
  }) {
    final topFormality = _getFormalityValue(topStyle);
    final bottomFormality = _getFormalityValue(bottomStyle);

    // Calculate variance
    final variance = (topFormality - bottomFormality).abs();

    // Convert variance to score (smaller variance = higher score)
    // Max variance is 6 (formal=9, streetwear=3)
    if (variance == 0) return 0.95;
    if (variance <= 1) return 0.85;
    if (variance <= 2) return 0.7;
    if (variance <= 3) return 0.5;
    if (variance <= 4) return 0.3;
    return 0.15;
  }

  int _getFormalityValue(WardrobeStyle style) {
    switch (style) {
      case WardrobeStyle.formal:
        return 9;
      case WardrobeStyle.vintage:
        return 6;
      case WardrobeStyle.minimalist:
        return 5;
      case WardrobeStyle.casual:
        return 4;
      case WardrobeStyle.streetwear:
        return 3;
    }
  }

  /// Weather Compatibility Score (0.0 - 1.0)
  double _calculateWeatherCompatibility({
    required WardrobeItemModel top,
    required WardrobeItemModel bottom,
    WeatherModel? weather,
  }) {
    // If no weather data, return neutral score
    if (weather == null) {
      return 0.5;
    }

    double score = 0.5;

    // Hot weather (< 25°C): prefer light, casual clothing
    if (weather.isHot) {
      if (top.style == WardrobeStyle.casual || top.style == WardrobeStyle.minimalist) {
        score += 0.2;
      }
      if (top.style == WardrobeStyle.formal) {
        score -= 0.1; // Formal may be too warm
      }
    }
    // Cold weather (< 10°C): prefer layered/formal
    else if (weather.isCold) {
      if (top.style == WardrobeStyle.formal || top.style == WardrobeStyle.minimalist) {
        score += 0.2;
      }
      if (bottom.style == WardrobeStyle.streetwear) {
        score -= 0.1;
      }
    }
    // Rainy: prefer durable materials (simplified - just style check)
    else if (weather.isRainy) {
      if (top.style == WardrobeStyle.casual) {
        score += 0.1;
      }
    }

    // Clamp score between 0 and 1
    return score.clamp(0.0, 1.0);
  }

  /// User Preference Match Score (0.0 - 1.0)
  double _calculateUserPreferenceMatch({
    required WardrobeItemModel top,
    required WardrobeItemModel bottom,
    List<String>? preferredStyles,
    List<String>? preferredColors,
  }) {
    // If no preferences, return neutral score
    if ((preferredStyles == null || preferredStyles.isEmpty) &&
        (preferredColors == null || preferredColors.isEmpty)) {
      return 0.5;
    }

    double topScore = 0.0;
    double bottomScore = 0.0;
    int criteria = 0;

    // Check style preferences
    if (preferredStyles != null && preferredStyles.isNotEmpty) {
      final topStyleMatch = preferredStyles
          .any((s) => s.toLowerCase() == top.style.displayName.toLowerCase());
      final bottomStyleMatch = preferredStyles.any(
          (s) => s.toLowerCase() == bottom.style.displayName.toLowerCase());

      if (topStyleMatch) topScore += 0.5;
      if (bottomStyleMatch) bottomScore += 0.5;
      criteria += 1;
    }

    // Check color preferences
    if (preferredColors != null && preferredColors.isNotEmpty) {
      final topColorMatch = preferredColors
          .any((c) => c.toLowerCase() == top.color.toLowerCase());
      final bottomColorMatch = preferredColors
          .any((c) => c.toLowerCase() == bottom.color.toLowerCase());

      if (topColorMatch) topScore += 0.5;
      if (bottomColorMatch) bottomScore += 0.5;
      criteria += 1;
    }

    if (criteria == 0) return 0.5;

    // Average the scores
    return ((topScore + bottomScore) / 2).clamp(0.0, 1.0);
  }

  /// Calculate final score (0 - 100) from breakdown
  double calculateFinalScore(OutfitScoreBreakdown breakdown) {
    return breakdown.calculateTotal() * 10;
  }
}
