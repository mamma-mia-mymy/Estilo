import 'wardrobe_item_model.dart';

class OutfitModel {
  final WardrobeItemModel top;
  final WardrobeItemModel bottom;
  final double totalScore;
  final OutfitScoreBreakdown scoreBreakdown;

  const OutfitModel({
    required this.top,
    required this.bottom,
    required this.totalScore,
    required this.scoreBreakdown,
  });

  OutfitModel copyWith({
    WardrobeItemModel? top,
    WardrobeItemModel? bottom,
    double? totalScore,
    OutfitScoreBreakdown? scoreBreakdown,
  }) {
    return OutfitModel(
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
      totalScore: totalScore ?? this.totalScore,
      scoreBreakdown: scoreBreakdown ?? this.scoreBreakdown,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutfitModel &&
          runtimeType == other.runtimeType &&
          top.id == other.top.id &&
          bottom.id == other.bottom.id;

  @override
  int get hashCode => top.id.hashCode ^ bottom.id.hashCode;
}

class OutfitScoreBreakdown {
  final double colorHarmony;
  final double styleConsistency;
  final double formalityAlignment;
  final double weatherCompatibility;
  final double userPreferenceMatch;

  const OutfitScoreBreakdown({
    required this.colorHarmony,
    required this.styleConsistency,
    required this.formalityAlignment,
    required this.weatherCompatibility,
    required this.userPreferenceMatch,
  });

  factory OutfitScoreBreakdown.zero() {
    return const OutfitScoreBreakdown(
      colorHarmony: 0,
      styleConsistency: 0,
      formalityAlignment: 0,
      weatherCompatibility: 0,
      userPreferenceMatch: 0,
    );
  }

  double calculateTotal() {
    return (colorHarmony * 0.25) +
        (styleConsistency * 0.25) +
        (formalityAlignment * 0.20) +
        (weatherCompatibility * 0.15) +
        (userPreferenceMatch * 0.15);
  }

  String get highestCriterion {
    final scores = {
      'Color Harmony': colorHarmony,
      'Style Consistency': styleConsistency,
      'Formality Alignment': formalityAlignment,
      'Weather Compatibility': weatherCompatibility,
      'User Preference Match': userPreferenceMatch,
    };
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String get lowestCriterion {
    final scores = {
      'Color Harmony': colorHarmony,
      'Style Consistency': styleConsistency,
      'Formality Alignment': formalityAlignment,
      'Weather Compatibility': weatherCompatibility,
      'User Preference Match': userPreferenceMatch,
    };
    return scores.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  OutfitScoreBreakdown copyWith({
    double? colorHarmony,
    double? styleConsistency,
    double? formalityAlignment,
    double? weatherCompatibility,
    double? userPreferenceMatch,
  }) {
    return OutfitScoreBreakdown(
      colorHarmony: colorHarmony ?? this.colorHarmony,
      styleConsistency: styleConsistency ?? this.styleConsistency,
      formalityAlignment: formalityAlignment ?? this.formalityAlignment,
      weatherCompatibility: weatherCompatibility ?? this.weatherCompatibility,
      userPreferenceMatch: userPreferenceMatch ?? this.userPreferenceMatch,
    );
  }
}
