import '../models/wardrobe_item_model.dart';
import '../models/outfit_model.dart';

class OutfitGeneratorService {
  /// Generate all possible outfit combinations
  /// Returns every top paired with every bottom
  List<OutfitModel> generateCombinations({
    required List<WardrobeItemModel> tops,
    required List<WardrobeItemModel> bottoms,
    required OutfitScoreBreakdown Function(WardrobeItemModel, WardrobeItemModel)
        scoreCalculator,
  }) {
    final combinations = <OutfitModel>[];

    // If no tops or bottoms, return empty list
    if (tops.isEmpty || bottoms.isEmpty) {
      return combinations;
    }

    // Generate all combinations: every top with every bottom
    for (final top in tops) {
      for (final bottom in bottoms) {
        final breakdown = scoreCalculator(top, bottom);
        final totalScore = breakdown.calculateTotal();

        combinations.add(OutfitModel(
          top: top,
          bottom: bottom,
          totalScore: totalScore,
          scoreBreakdown: breakdown,
        ));
      }
    }

    // Sort by total score (highest first)
    combinations.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return combinations;
  }

  /// Get total number of possible combinations
  int getCombinationCount(int topsCount, int bottomsCount) {
    return topsCount * bottomsCount;
  }

  /// Filter combinations by minimum score threshold
  List<OutfitModel> filterByMinimumScore({
    required List<OutfitModel> combinations,
    required double minimumScore,
  }) {
    return combinations
        .where((outfit) => outfit.totalScore >= minimumScore)
        .toList();
  }

  /// Get top N outfits
  List<OutfitModel> getTopRecommendations({
    required List<OutfitModel> combinations,
    required int count,
  }) {
    if (combinations.isEmpty) return [];
    return combinations.take(count).toList();
  }

  /// Group combinations by score range
  Map<String, List<OutfitModel>> groupByScoreRange({
    required List<OutfitModel> combinations,
  }) {
    return {
      'excellent':
          combinations.where((o) => o.totalScore >= 0.8).toList(),
      'good': combinations.where((o) => o.totalScore >= 0.6 && o.totalScore < 0.8).toList(),
      'average': combinations.where((o) => o.totalScore >= 0.4 && o.totalScore < 0.6).toList(),
      'poor': combinations.where((o) => o.totalScore < 0.4).toList(),
    };
  }

  /// Find the best outfit from combinations
  OutfitModel? findBestOutfit(List<OutfitModel> combinations) {
    if (combinations.isEmpty) return null;
    return combinations.first;
  }

  /// Get random outfit for "surprise me" feature
  OutfitModel? getRandomOutfit(List<OutfitModel> combinations) {
    if (combinations.isEmpty) return null;
    final randomIndex = DateTime.now().millisecond % combinations.length;
    return combinations[randomIndex];
  }
}
