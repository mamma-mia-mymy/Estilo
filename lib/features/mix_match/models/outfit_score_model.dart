class OutfitScoreModel {
  final double totalScore; // 0–100
  final double colorHarmony;
  final double styleConsistency;
  final double formalityAlignment;
  final double weatherCompatibility;
  final double userPreferenceMatch;
  final String explanation;

  const OutfitScoreModel({
    required this.totalScore,
    required this.colorHarmony,
    required this.styleConsistency,
    required this.formalityAlignment,
    required this.weatherCompatibility,
    required this.userPreferenceMatch,
    this.explanation = '',
  });

  OutfitScoreModel copyWith({String? explanation}) => OutfitScoreModel(
        totalScore: totalScore,
        colorHarmony: colorHarmony,
        styleConsistency: styleConsistency,
        formalityAlignment: formalityAlignment,
        weatherCompatibility: weatherCompatibility,
        userPreferenceMatch: userPreferenceMatch,
        explanation: explanation ?? this.explanation,
      );
}
