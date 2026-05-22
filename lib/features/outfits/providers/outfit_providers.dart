import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wardrobe_item_model.dart';
import '../models/outfit_model.dart';
import '../models/weather_model.dart';
import '../services/wardrobe_service.dart';
import '../services/outfit_generator_service.dart';
import '../services/outfit_scorer_service.dart';
import '../services/weather_service.dart';

// Firestore provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Wardrobe service provider
final wardrobeServiceProvider = Provider<WardrobeService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return WardrobeService(firestore: firestore);
});

// Outfit generator service provider
final outfitGeneratorServiceProvider = Provider<OutfitGeneratorService>((ref) {
  return OutfitGeneratorService();
});

// Outfit scorer service provider
final outfitScorerServiceProvider = Provider<OutfitScorerService>((ref) {
  return OutfitScorerService();
});

// Weather service provider
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

// User ID provider - from Firebase Auth
final userIdProvider = Provider<String>((ref) {
  final firebaseAuth = FirebaseAuth.instance;
  return firebaseAuth.currentUser?.uid ?? 'demo-user';
});

// Wardrobe state
class WardrobeState {
  final List<WardrobeItemModel> items;
  final List<WardrobeItemModel> tops;
  final List<WardrobeItemModel> bottoms;
  final bool isLoading;
  final String? errorMessage;

  const WardrobeState({
    this.items = const [],
    this.tops = const [],
    this.bottoms = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  WardrobeState copyWith({
    List<WardrobeItemModel>? items,
    List<WardrobeItemModel>? tops,
    List<WardrobeItemModel>? bottoms,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WardrobeState(
      items: items ?? this.items,
      tops: tops ?? this.tops,
      bottoms: bottoms ?? this.bottoms,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  bool get hasEnoughItems => tops.isNotEmpty && bottoms.isNotEmpty;
  int get totalCombinations => tops.length * bottoms.length;
}

// Wardrobe notifier
class WardrobeNotifier extends StateNotifier<WardrobeState> {
  final WardrobeService _wardrobeService;
  final String userId;

  WardrobeNotifier(this._wardrobeService, this.userId) : super(const WardrobeState()) {
    loadWardrobe();
  }

  Future<void> loadWardrobe() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final items = await _wardrobeService.getWardrobeItems(userId);
      final tops = items.where((item) => item.category == WardrobeCategory.top).toList();
      final bottoms = items.where((item) => item.category == WardrobeCategory.bottom).toList();

      state = state.copyWith(
        items: items,
        tops: tops,
        bottoms: bottoms,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load wardrobe: $e',
      );
    }
  }

  Future<void> addItem({
    required String imageUrl,
    required WardrobeCategory category,
    required String color,
    required WardrobeStyle style,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _wardrobeService.addWardrobeItem(
        userId: userId,
        imageUrl: imageUrl,
        category: category,
        color: color,
        style: style,
      );

      // Reload wardrobe after adding
      await loadWardrobe();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add item: $e',
      );
    }
  }

  Future<void> deleteItem(String itemId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _wardrobeService.deleteWardrobeItem(itemId);
      await loadWardrobe();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete item: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Wardrobe provider
final wardrobeProvider = StateNotifierProvider<WardrobeNotifier, WardrobeState>((ref) {
  final wardrobeService = ref.watch(wardrobeServiceProvider);
  final userId = ref.watch(userIdProvider);
  
  return WardrobeNotifier(wardrobeService, userId);
});

// Weather state
class WeatherState {
  final WeatherModel? weather;
  final bool isLoading;
  final String? errorMessage;

  const WeatherState({
    this.weather,
    this.isLoading = false,
    this.errorMessage,
  });

  WeatherState copyWith({
    WeatherModel? weather,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WeatherState(
      weather: weather ?? this.weather,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Weather notifier
class WeatherNotifier extends StateNotifier<WeatherState> {
  final WeatherService _weatherService;

  WeatherNotifier(this._weatherService) : super(const WeatherState()) {
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final weather = await _weatherService.getWeatherForCurrentLocation();
      state = state.copyWith(weather: weather, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        weather: WeatherModel.placeholder(),
        isLoading: false,
        errorMessage: 'Using cached weather',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Weather provider
final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  final weatherService = ref.watch(weatherServiceProvider);
  return WeatherNotifier(weatherService);
});

// Outfit recommendation state
class OutfitRecommendationState {
  final List<OutfitModel> recommendations;
  final OutfitModel? bestOutfit;
  final bool isLoading;
  final String? errorMessage;

  const OutfitRecommendationState({
    this.recommendations = const [],
    this.bestOutfit,
    this.isLoading = false,
    this.errorMessage,
  });

  OutfitRecommendationState copyWith({
    List<OutfitModel>? recommendations,
    OutfitModel? bestOutfit,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OutfitRecommendationState(
      recommendations: recommendations ?? this.recommendations,
      bestOutfit: bestOutfit ?? this.bestOutfit,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Outfit recommendation notifier
class OutfitRecommendationNotifier extends StateNotifier<OutfitRecommendationState> {
  final OutfitGeneratorService _generatorService;
  final OutfitScorerService _scorerService;
  final WeatherService _weatherService;
  final List<WardrobeItemModel> tops;
  final List<WardrobeItemModel> bottoms;
  final List<String>? preferredStyles;
  final List<String>? preferredColors;
  final String? skinTone;

  OutfitRecommendationNotifier({
    required OutfitGeneratorService generatorService,
    required OutfitScorerService scorerService,
    required WeatherService weatherService,
    required this.tops,
    required this.bottoms,
    this.preferredStyles,
    this.preferredColors,
    this.skinTone,
  })  : _generatorService = generatorService,
        _scorerService = scorerService,
        _weatherService = weatherService,
        super(const OutfitRecommendationState()) {
    generateRecommendations();
  }

  void generateRecommendations() {
    if (tops.isEmpty || bottoms.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Upload at least one top and one bottom to generate outfits.',
        recommendations: [],
        bestOutfit: null,
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final weather = _weatherService.getCachedWeather();

      // Score calculator function
      OutfitScoreBreakdown scoreCalculator(WardrobeItemModel top, WardrobeItemModel bottom) {
        return _scorerService.calculateScore(
          top: top,
          bottom: bottom,
          weather: weather,
          userPreferredStyles: preferredStyles,
          userPreferredColors: preferredColors,
          userSkinTone: skinTone,
        );
      }

      // Generate combinations
      final combinations = _generatorService.generateCombinations(
        tops: tops,
        bottoms: bottoms,
        scoreCalculator: scoreCalculator,
      );

      final bestOutfit = _generatorService.findBestOutfit(combinations);

      state = state.copyWith(
        recommendations: combinations,
        bestOutfit: bestOutfit,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to generate recommendations: $e',
      );
    }
  }

  void regenerate() {
    generateRecommendations();
  }
}

// Outfit recommendation provider factory
final outfitRecommendationProvider = StateNotifierProvider.family<
    OutfitRecommendationNotifier, OutfitRecommendationState, void>((ref, _) {
  final generatorService = ref.watch(outfitGeneratorServiceProvider);
  final scorerService = ref.watch(outfitScorerServiceProvider);
  final weatherService = ref.watch(weatherServiceProvider);
  final wardrobeState = ref.watch(wardrobeProvider);

  return OutfitRecommendationNotifier(
    generatorService: generatorService,
    scorerService: scorerService,
    weatherService: weatherService,
    tops: wardrobeState.tops,
    bottoms: wardrobeState.bottoms,
  );
});

// Provider for loading state
final isGeneratingRecommendationsProvider = Provider<bool>((ref) {
  return ref.watch(wardrobeProvider).isLoading;
});
