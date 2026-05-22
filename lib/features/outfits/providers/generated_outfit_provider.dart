import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/generated_outfit_model.dart';
import '../services/generated_outfit_service.dart';

final generatedOutfitServiceProvider = Provider((ref) {
  return GeneratedOutfitService();
});

/// Stream provider for all user outfits (recent first)
final userOutfitsProvider = StreamProvider<List<GeneratedOutfit>>((ref) {
  final service = ref.watch(generatedOutfitServiceProvider);
  return service.getUserOutfitsStream();
});

/// Stream provider for recent outfits (last 5)
final recentOutfitsProvider = StreamProvider<List<GeneratedOutfit>>((ref) {
  final service = ref.watch(generatedOutfitServiceProvider);
  return service.getRecentOutfitsStream();
});

/// Stream provider for saved/favorited outfits
final savedOutfitsProvider = StreamProvider<List<GeneratedOutfit>>((ref) {
  final service = ref.watch(generatedOutfitServiceProvider);
  return service.getSavedOutfitsStream();
});

/// Provider to get a specific outfit
final outfitByIdProvider = FutureProvider.family<GeneratedOutfit?, String>((ref, outfitId) async {
  final service = ref.watch(generatedOutfitServiceProvider);
  return service.getOutfitById(outfitId);
});

/// Provider to save a new outfit
final saveOutfitProvider = FutureProvider.family<String, SaveOutfitParams>((ref, params) async {
  final service = ref.watch(generatedOutfitServiceProvider);
  final id = await service.saveOutfit(
    topId: params.topId,
    bottomId: params.bottomId,
    topImageUrl: params.topImageUrl,
    bottomImageUrl: params.bottomImageUrl,
    score: params.score,
    explanation: params.explanation,
    temperature: params.temperature,
    weatherCondition: params.weatherCondition,
  );
  // Invalidate caches to refresh UI
  ref.invalidate(userOutfitsProvider);
  ref.invalidate(recentOutfitsProvider);
  return id;
});

/// Provider to toggle favorite
final toggleFavoriteProvider = FutureProvider.family<void, ToggleFavoriteParams>((ref, params) async {
  final service = ref.watch(generatedOutfitServiceProvider);
  await service.toggleFavorite(params.outfitId, params.isFavorite);
  // Invalidate caches to refresh UI
  ref.invalidate(userOutfitsProvider);
  ref.invalidate(savedOutfitsProvider);
  ref.invalidate(recentOutfitsProvider);
});

/// Provider to delete an outfit
final deleteOutfitProvider = FutureProvider.family<void, String>((ref, outfitId) async {
  final service = ref.watch(generatedOutfitServiceProvider);
  await service.deleteOutfit(outfitId);
  // Invalidate caches to refresh UI
  ref.invalidate(userOutfitsProvider);
  ref.invalidate(savedOutfitsProvider);
  ref.invalidate(recentOutfitsProvider);
});

// ── Parameter classes ────────────────────────────────────────────────

class SaveOutfitParams {
  final String topId;
  final String bottomId;
  final String topImageUrl;
  final String bottomImageUrl;
  final double score;
  final String explanation;
  final double temperature;
  final String weatherCondition;

  SaveOutfitParams({
    required this.topId,
    required this.bottomId,
    required this.topImageUrl,
    required this.bottomImageUrl,
    required this.score,
    required this.explanation,
    required this.temperature,
    required this.weatherCondition,
  });
}

class ToggleFavoriteParams {
  final String outfitId;
  final bool isFavorite;

  ToggleFavoriteParams({
    required this.outfitId,
    required this.isFavorite,
  });
}
