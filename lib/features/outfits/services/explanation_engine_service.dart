import '../models/wardrobe_item_model.dart';
import '../models/outfit_model.dart';
import '../models/weather_model.dart';
import '../models/explanation_model.dart';

class ExplanationEngineService {
  /// Generate explanation for an outfit based on score breakdown
  ExplanationModel generateExplanation({
    required OutfitModel outfit,
    WeatherModel? weather,
  }) {
    final breakdown = outfit.scoreBreakdown;

    // Generate explanations based on each criterion
    return ExplanationModel.fromScoreBreakdown(
      breakdown: breakdown,
      topStyle: outfit.top.style.displayName,
      bottomStyle: outfit.bottom.style.displayName,
      topColor: outfit.top.color,
      bottomColor: outfit.bottom.color,
      weatherCondition: weather?.condition ?? 'Unknown',
      temperature: weather?.temperature ?? 25.0,
    );
  }

  /// Generate a short summary for the outfit
  String generateShortSummary(OutfitModel outfit) {
    final breakdown = outfit.scoreBreakdown;
    final score = outfit.totalScore * 10;

    if (score >= 80) {
      return 'Excellent match with ${score.toStringAsFixed(0)}/100 score.';
    } else if (score >= 60) {
      return 'Good combination scoring ${score.toStringAsFixed(0)}/100.';
    } else if (score >= 40) {
      return 'Average pairing at ${score.toStringAsFixed(0)}/100.';
    } else {
      return 'There might be better options for this outfit.';
    }
  }

  /// Generate detailed feedback for each criterion
  Map<String, String> generateDetailedFeedback({
    required OutfitModel outfit,
    WeatherModel? weather,
  }) {
    final breakdown = outfit.scoreBreakdown;
    final weatherTemp = weather?.temperature ?? 25.0;

    return {
      'colorHarmony': _getColorHarmonyFeedback(breakdown.colorHarmony),
      'styleConsistency': _getStyleConsistencyFeedback(breakdown.styleConsistency),
      'formalityAlignment': _getFormalityFeedback(breakdown.formalityAlignment),
      'weatherCompatibility': _getWeatherFeedback(
        breakdown.weatherCompatibility,
        weatherTemp,
        weather?.condition,
      ),
      'userPreferenceMatch': _getPreferenceFeedback(breakdown.userPreferenceMatch),
    };
  }

  String _getColorHarmonyFeedback(double score) {
    if (score >= 0.8) {
      return 'The outfit colors complement each other effectively.';
    } else if (score >= 0.5) {
      return 'The colors work reasonably well together.';
    } else {
      return 'The color combination could be improved.';
    }
  }

  String _getStyleConsistencyFeedback(double score) {
    if (score >= 0.8) {
      return 'Both pieces maintain a cohesive aesthetic.';
    } else if (score >= 0.5) {
      return 'The styles have some consistency.';
    } else {
      return 'The styles may conflict with each other.';
    }
  }

  String _getFormalityFeedback(double score) {
    if (score >= 0.8) {
      return 'The formality levels are well-matched.';
    } else if (score >= 0.5) {
      return 'The formality is somewhat aligned.';
    } else {
      return 'The formality mismatch may be noticeable.';
    }
  }

  String _getWeatherFeedback(double score, double temperature, String? condition) {
    if (score >= 0.8) {
      return 'Great choice for current weather conditions.';
    } else if (score >= 0.5) {
      return 'Suitable for today\'s weather.';
    } else {
      if (temperature >= 25) {
        return 'The outfit may feel slightly warm for current weather conditions.';
      } else if (temperature < 15) {
        return 'The outfit may not provide enough warmth.';
      } else {
        return 'The outfit may not be ideal for current weather.';
      }
    }
  }

  String _getPreferenceFeedback(double score) {
    if (score >= 0.8) {
      return 'The outfit strongly aligns with your personal style preferences.';
    } else if (score >= 0.5) {
      return 'The outfit matches some of your preferences.';
    } else {
      return 'This may not match your preferred style.';
    }
  }

  /// Generate recommendation text
  String generateRecommendation(OutfitModel outfit) {
    final score = outfit.totalScore * 10;

    if (score >= 80) {
      return 'Great choice! This outfit scores well across most criteria.';
    } else if (score >= 60) {
      return 'A solid choice. Consider the highlighted points for improvement.';
    } else if (score >= 40) {
      return 'This outfit works for casual occasions.';
    } else {
      return 'Try exploring other combinations for a better match.';
    }
  }
}
