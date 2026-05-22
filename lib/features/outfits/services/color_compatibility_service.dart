import '../models/wardrobe_item_model.dart';

enum ColorCompatibilityLevel {
  high,
  medium,
  low,
}

/// Deterministic color compatibility service
/// Uses rule-based scoring instead of ML/AI
class ColorCompatibilityService {
  /// Neutral colors that pair well with most colors
  static const Set<String> neutralColors = {
    'black',
    'white',
    'gray',
    'grey',
    'navy',
    'cream',
    'beige',
  };

  /// Warm skin tones
  static const Set<String> warmSkinTones = {
    'warm',
    'beige',
    'olive',
    'brown',
    'tan',
  };

  /// Cool skin tones
  static const Set<String> coolSkinTones = {
    'cool',
    'fair',
    'pink',
    'rose',
  };

  /// High compatibility color pairs
  static const Map<String, Set<String>> highCompatibilityPairs = {
    'black': {'white', 'gray', 'red', 'navy', 'cream', 'beige', 'pink', 'green'},
    'white': {'black', 'navy', 'gray', 'brown', 'beige', 'blue', 'cream'},
    'gray': {'white', 'black', 'navy', 'blue', 'burgundy', 'cream', 'pink'},
    'navy': {'white', 'gray', 'beige', 'brown', 'khaki', 'cream', 'orange'},
    'beige': {'white', 'brown', 'navy', 'black', 'green', 'cream', 'tan'},
    'cream': {'brown', 'navy', 'black', 'gray', 'blue', 'green'},
    'brown': {'beige', 'cream', 'navy', 'white', 'green', 'orange', 'tan'},
  };

  /// Medium compatibility color pairs
  static const Map<String, Set<String>> mediumCompatibilityPairs = {
    'blue': {'green', 'gray', 'brown', 'white', 'yellow'},
    'green': {'blue', 'brown', 'beige', 'gray', 'yellow', 'cream'},
    'red': {'black', 'white', 'gray', 'navy', 'blue'},
    'burgundy': {'black', 'gray', 'navy', 'cream', 'green'},
    'khaki': {'navy', 'white', 'brown', 'beige', 'green'},
    'tan': {'brown', 'navy', 'white', 'beige', 'green'},
  };

  /// Low compatibility color pairs (conflicting colors)
  static const Set<String> conflictingColors = {
    'orange',
    'purple',
    'neon green',
    'neon yellow',
    'neon pink',
    'bright yellow',
    'magenta',
  };

  /// Get compatibility score between two colors (0.0 - 1.0)
  double getColorCompatibilityScore(String color1, String color2) {
    final normalizedColor1 = _normalizeColor(color1);
    final normalizedColor2 = _normalizeColor(color2);

    // Same color - monochromatic is usually good
    if (normalizedColor1 == normalizedColor2) {
      return 0.9;
    }

    // Check if either color is neutral
    if (_isNeutral(normalizedColor1) || _isNeutral(normalizedColor2)) {
      return 0.85;
    }

    // Check high compatibility pairs
    if (_isHighCompatibility(normalizedColor1, normalizedColor2)) {
      return 0.8;
    }

    // Check medium compatibility pairs
    if (_isMediumCompatibility(normalizedColor1, normalizedColor2)) {
      return 0.5;
    }

    // Check low compatibility (conflicting)
    if (_isLowCompatibility(normalizedColor1, normalizedColor2)) {
      return 0.2;
    }

    // Default to medium-low compatibility
    return 0.4;
  }

  /// Get compatibility level
  ColorCompatibilityLevel getCompatibilityLevel(String color1, String color2) {
    final score = getColorCompatibilityScore(color1, color2);
    if (score >= 0.7) return ColorCompatibilityLevel.high;
    if (score >= 0.4) return ColorCompatibilityLevel.medium;
    return ColorCompatibilityLevel.low;
  }

  /// Normalize color string
  String _normalizeColor(String color) {
    return color.toLowerCase().trim();
  }

  /// Check if color is neutral
  bool _isNeutral(String color) {
    return neutralColors.any((neutral) => color.contains(neutral));
  }

/// Check high compatibility
  bool _isHighCompatibility(String color1, String color2) {
    final set1 = highCompatibilityPairs[color1];
    final set2 = highCompatibilityPairs[color2];
    return (set1 != null && set1.contains(color2)) ||
        (set2 != null && set2.contains(color1));
  }

  /// Check medium compatibility
  bool _isMediumCompatibility(String color1, String color2) {
    final set1 = mediumCompatibilityPairs[color1];
    final set2 = mediumCompatibilityPairs[color2];
    return (set1 != null && set1.contains(color2)) ||
        (set2 != null && set2.contains(color1));
  }

  /// Check low compatibility
  bool _isLowCompatibility(String color1, String color2) {
    return conflictingColors.any((c) => color1.contains(c) || color2.contains(c));
  }

  /// Get skin tone compatibility score
  /// Warm skin tones pair better with warm colors
  /// Cool skin tones pair better with cool colors
  double getSkinToneCompatibilityScore({
    required String clothingColor,
    required String userSkinTone,
  }) {
    final normalizedClothingColor = _normalizeColor(clothingColor);
    final normalizedSkinTone = userSkinTone.toLowerCase().trim();

    // Determine clothing color temperature
    final isClothingWarm = _isWarmColor(normalizedClothingColor);
    final isClothingCool = _isCoolColor(normalizedClothingColor);

    // Determine skin tone temperature
    final isSkinWarm = warmSkinTones.any((t) => normalizedSkinTone.contains(t));
    final isSkinCool = coolSkinTones.any((t) => normalizedSkinTone.contains(t));

    // Match - both warm or both cool
    if ((isClothingWarm && isSkinWarm) || (isClothingCool && isSkinCool)) {
      return 0.9;
    }

    // Neutral colors work with any skin tone
    if (_isNeutral(normalizedClothingColor)) {
      return 0.85;
    }

    // Mismatch
    if ((isClothingWarm && isSkinCool) || (isClothingCool && isSkinWarm)) {
      return 0.6;
    }

    // Default
    return 0.7;
  }

  /// Check if color is warm
  bool _isWarmColor(String color) {
    const warmColors = {
      'red',
      'orange',
      'yellow',
      'brown',
      'beige',
      'tan',
      'coral',
      'peach',
      'burgundy',
      'maroon',
    };
    return warmColors.any((c) => color.contains(c));
  }

  /// Check if color is cool
  bool _isCoolColor(String color) {
    const coolColors = {
      'blue',
      'green',
      'purple',
      'gray',
      'navy',
      'teal',
      'cyan',
      'mint',
      'lavender',
      'pink',
    };
    return coolColors.any((c) => color.contains(c));
  }

  /// Get recommended colors for user's skin tone
  List<String> getRecommendedColorsForSkinTone(String userSkinTone) {
    final normalizedSkinTone = userSkinTone.toLowerCase().trim();
    final isWarm = warmSkinTones.any((t) => normalizedSkinTone.contains(t));
    final isCool = coolSkinTones.any((t) => normalizedSkinTone.contains(t));

    if (isWarm) {
      return [
        'burgundy',
        'brown',
        'beige',
        'cream',
        'forest green',
        'coral',
        'tan',
      ];
    } else if (isCool) {
      return [
        'navy',
        'royal blue',
        'emerald',
        'silver',
        'burgundy',
        'lavender',
        'rose',
      ];
    }

    // Neutral skin tone - recommend versatile colors
    return [
      'black',
      'white',
      'navy',
      'gray',
      'beige',
      'cream',
    ];
  }
}
