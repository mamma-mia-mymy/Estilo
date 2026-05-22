import 'outfit_model.dart';

class ExplanationModel {
  final String summary;
  final List<String> positivePoints;
  final List<String> negativePoints;
  final String recommendation;

  const ExplanationModel({
    required this.summary,
    required this.positivePoints,
    required this.negativePoints,
    required this.recommendation,
  });

  factory ExplanationModel.fromScoreBreakdown({
    required OutfitScoreBreakdown breakdown,
    required String topStyle,
    required String bottomStyle,
    required String topColor,
    required String bottomColor,
    required String weatherCondition,
    required double temperature,
  }) {
    final positivePoints = <String>[];
    final negativePoints = <String>[];
    String recommendation = '';

    // Color Harmony Analysis
    if (breakdown.colorHarmony >= 0.8) {
      positivePoints.add('The outfit colors complement each other effectively.');
    } else if (breakdown.colorHarmony >= 0.5) {
      positivePoints.add('The colors work reasonably well together.');
    } else {
      negativePoints.add('The color combination could be improved.');
    }

    // Style Consistency Analysis
    if (breakdown.styleConsistency >= 0.8) {
      positivePoints.add('Both pieces maintain a cohesive aesthetic.');
    } else if (breakdown.styleConsistency >= 0.5) {
      positivePoints.add('The styles have some consistency.');
    } else {
      negativePoints.add('The styles may conflict with each other.');
    }

    // Formality Alignment Analysis
    if (breakdown.formalityAlignment >= 0.8) {
      positivePoints.add('The formality levels are well-matched.');
    } else if (breakdown.formalityAlignment >= 0.5) {
      positivePoints.add('The formality is somewhat aligned.');
    } else {
      negativePoints.add('The formality mismatch may be noticeable.');
    }

    // Weather Compatibility Analysis
    if (breakdown.weatherCompatibility >= 0.8) {
      positivePoints.add('Great choice for current weather conditions.');
    } else if (breakdown.weatherCompatibility >= 0.5) {
      positivePoints.add('Suitable for today\'s weather.');
    } else {
      if (temperature >= 25) {
        negativePoints.add('The outfit may feel slightly warm for current weather conditions.');
      } else if (temperature < 15) {
        negativePoints.add('The outfit may not provide enough warmth.');
      } else {
        negativePoints.add('The outfit may not be ideal for current weather.');
      }
    }

    // User Preference Match Analysis
    if (breakdown.userPreferenceMatch >= 0.8) {
      positivePoints.add('The outfit strongly aligns with your personal style preferences.');
    } else if (breakdown.userPreferenceMatch >= 0.5) {
      positivePoints.add('The outfit matches some of your preferences.');
    } else {
      negativePoints.add('This may not match your preferred style.');
    }

    // Generate summary
    String summary;
    if (positivePoints.length >= 3) {
      summary = 'This outfit works well because the colors complement each other and both pieces share a consistent aesthetic.';
    } else if (positivePoints.isEmpty) {
      summary = 'This outfit has potential but could be improved with better color or style pairing.';
    } else {
      summary = 'This outfit has some strong points: ${positivePoints.first}';
    }

    // Generate recommendation
    if (breakdown.calculateTotal() >= 0.7) {
      recommendation = 'Great choice! This outfit scores well across most criteria.';
    } else if (breakdown.calculateTotal() >= 0.5) {
      recommendation = 'A solid choice. Consider the highlighted points for improvement.';
    } else {
      recommendation = 'Try exploring other combinations for a better match.';
    }

    return ExplanationModel(
      summary: summary,
      positivePoints: positivePoints,
      negativePoints: negativePoints,
      recommendation: recommendation,
    );
  }

  String toDisplayString() {
    final buffer = StringBuffer();
    buffer.writeln(summary);
    
    if (positivePoints.isNotEmpty) {
      buffer.writeln('\n✓ ${positivePoints.join('\n✓ ')}');
    }
    
    if (negativePoints.isNotEmpty) {
      buffer.writeln('\n✗ ${negativePoints.join('\n✗ ')}');
    }
    
    buffer.writeln('\n$recommendation');
    
    return buffer.toString();
  }
}
