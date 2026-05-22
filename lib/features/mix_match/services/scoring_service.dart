import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/outfit_score_model.dart';

class ScoringService {
  // ── Color compatibility map ───────────────────────────────────────
  static const Map<String, List<String>> _highCompatibility = {
    'black':  ['white', 'gray', 'beige', 'navy', 'red', 'pink', 'blue', 'green', 'purple', 'yellow', 'orange', 'brown'],
    'white':  ['black', 'gray', 'navy', 'blue', 'beige', 'brown', 'red', 'pink', 'green', 'purple'],
    'gray':   ['black', 'white', 'navy', 'blue', 'pink', 'purple', 'beige'],
    'beige':  ['brown', 'white', 'black', 'navy', 'gray', 'olive', 'cream'],
    'navy':   ['white', 'beige', 'gray', 'black', 'brown', 'red'],
    'blue':   ['white', 'gray', 'black', 'brown', 'beige', 'navy'],
    'brown':  ['beige', 'white', 'navy', 'cream', 'olive', 'black'],
    'green':  ['white', 'black', 'beige', 'brown', 'navy'],
    'red':    ['black', 'white', 'navy', 'gray'],
    'pink':   ['white', 'gray', 'black', 'navy', 'beige'],
    'yellow': ['black', 'white', 'navy', 'gray'],
    'orange': ['black', 'white', 'navy', 'brown'],
    'purple': ['white', 'black', 'gray', 'beige'],
  };

  static const List<String> _neutrals = [
    'black', 'white', 'gray', 'beige', 'brown', 'navy'
  ];

  // ── Formality values ──────────────────────────────────────────────
  static const Map<String, double> _formalityMap = {
    'formal':      9.0,
    'vintage':     6.0,
    'minimalist':  5.0,
    'casual':      4.0,
    'streetwear':  3.0,
  };

// ── Main scoring method ───────────────────────────────────────────
static Future<OutfitScoreModel> scoreOutfit({
    required String topColor,
    required String topStyle,
    required String bottomColor,
    required String bottomStyle,
    required double temperature,
    required String weatherCondition,
    required List<String> userFavoriteColors,
    required List<String> userPreferredStyles,
    String occasion = 'Everyday',
  }) async {
    final color     = _scoreColorHarmony(topColor, bottomColor);
    final style     = _scoreStyleConsistency(topStyle, bottomStyle);
    final formality = _scoreFormalityAlignment(topStyle, bottomStyle, occasion);
    final weather   = _scoreWeatherCompatibility(topStyle, bottomStyle, temperature, weatherCondition);
    final pref      = _scoreUserPreference(topColor, bottomColor, topStyle, bottomStyle, userFavoriteColors, userPreferredStyles);

    final total = ((color * 0.25) + (style * 0.25) + (formality * 0.20) + (weather * 0.15) + (pref * 0.15)) * 10;

    return OutfitScoreModel(
      totalScore: total.clamp(0, 100),
      colorHarmony: color,
      styleConsistency: style,
      formalityAlignment: formality,
      weatherCompatibility: weather,
      userPreferenceMatch: pref,
    );
  }

  // ── Color Harmony (0–10) ──────────────────────────────────────────
  static double _scoreColorHarmony(String top, String bottom) {
    final t = top.toLowerCase();
    final b = bottom.toLowerCase();

    if (t == b) return 7.0; // monochromatic — good but not perfect

    final isTopNeutral    = _neutrals.contains(t);
    final isBottomNeutral = _neutrals.contains(b);

    if (isTopNeutral && isBottomNeutral) return 9.0;
    if (isTopNeutral || isBottomNeutral) return 8.0;

    final compatible = _highCompatibility[t] ?? [];
    if (compatible.contains(b)) return 8.0;

    return 4.0; // low compatibility
  }

  // ── Style Consistency (0–10) ──────────────────────────────────────
  static double _scoreStyleConsistency(String top, String bottom) {
    final t = top.toLowerCase();
    final b = bottom.toLowerCase();

    if (t == b) return 10.0;

    // Compatible pairs
    const compatible = {
      'casual':     ['minimalist', 'streetwear', 'vintage'],
      'formal':     ['minimalist'],
      'minimalist': ['casual', 'formal', 'vintage'],
      'streetwear': ['casual', 'vintage'],
      'vintage':    ['casual', 'minimalist', 'streetwear'],
    };

    final pairs = compatible[t] ?? [];
    if (pairs.contains(b)) return 7.0;

    // Clashing pairs
    const clashing = {
      'formal':     ['streetwear'],
      'streetwear': ['formal'],
    };

    final clashes = clashing[t] ?? [];
    if (clashes.contains(b)) return 2.0;

    return 5.0; // neutral
  }

// ── Formality Alignment (0–10) ────────────────────────────────────
  static double _scoreFormalityAlignment(String top, String bottom, String occasion) {
    final topF    = _formalityMap[top.toLowerCase()]    ?? 5.0;
    final bottomF = _formalityMap[bottom.toLowerCase()] ?? 5.0;
    final diff    = (topF - bottomF).abs();

    // Base formality alignment score
    double base;
    if (diff == 0)      base = 10.0;
    else if (diff <= 1) base = 8.0;
    else if (diff <= 2) base = 6.0;
    else if (diff <= 3) base = 4.0;
    else                base = 2.0;

    // Occasion modifier
    final avgFormality = (topF + bottomF) / 2;
    final occ = occasion.toLowerCase();

    if (occ == 'work') {
      // Work wants formality 5–9
      if (avgFormality >= 5) base = (base + 1).clamp(0, 10);
      else base = (base - 2).clamp(0, 10);
    } else if (occ == 'night out') {
      // Night out wants vintage/formal/streetwear
      if (avgFormality >= 6 || top.toLowerCase() == 'streetwear') {
        base = (base + 1).clamp(0, 10);
      }
    } else if (occ == 'gym') {
      // Gym wants casual/streetwear only
      if (top.toLowerCase() == 'casual' || top.toLowerCase() == 'streetwear') {
        base = (base + 2).clamp(0, 10);
      } else {
        base = (base - 3).clamp(0, 10);
      }
    } else if (occ == 'travel') {
      // Travel prefers casual/minimalist
      if (top.toLowerCase() == 'casual' || top.toLowerCase() == 'minimalist') {
        base = (base + 1).clamp(0, 10);
      }
    }
    // 'Everyday' — no modifier

    return base;
  }

  // ── Weather Compatibility (0–10) ──────────────────────────────────
  static double _scoreWeatherCompatibility(
    String top, String bottom, double temp, String condition) {
    double score = 7.0;

    // Temperature rules
    if (temp >= 30) {
      // Hot — prefer casual and light styles
      if (top.toLowerCase() == 'casual' || top.toLowerCase() == 'minimalist') score += 2;
      if (top.toLowerCase() == 'formal') score -= 2;
    } else if (temp >= 20) {
      score += 1; // comfortable range
    } else if (temp < 15) {
      // Cold — prefer layered/formal
      if (top.toLowerCase() == 'formal' || top.toLowerCase() == 'streetwear') score += 2;
      if (top.toLowerCase() == 'casual') score -= 1;
    }

    // Condition rules
    final c = condition.toLowerCase();
    if (c.contains('rain') && top.toLowerCase() == 'streetwear') score += 1;
    if (c.contains('rain') && top.toLowerCase() == 'casual')      score -= 1;

    return score.clamp(0, 10);
  }

  // ── User Preference Match (0–10) ──────────────────────────────────
  static double _scoreUserPreference(
    String topColor, String bottomColor,
    String topStyle, String bottomStyle,
    List<String> favoriteColors,
    List<String> preferredStyles,
  ) {
    if (favoriteColors.isEmpty && preferredStyles.isEmpty) return 5.0;

    double score = 5.0;
    int matches  = 0;
    int total    = 0;

    if (favoriteColors.isNotEmpty) {
      total += 2;
      final tc = topColor.toLowerCase();
      final bc = bottomColor.toLowerCase();
      final favLower = favoriteColors.map((c) => c.toLowerCase()).toList();
      if (favLower.contains(tc)) matches++;
      if (favLower.contains(bc)) matches++;
    }

    if (preferredStyles.isNotEmpty) {
      total += 2;
      final ts = topStyle.toLowerCase();
      final bs = bottomStyle.toLowerCase();
      final prefLower = preferredStyles.map((s) => s.toLowerCase()).toList();
      if (prefLower.contains(ts)) matches++;
      if (prefLower.contains(bs)) matches++;
    }

    if (total > 0) {
      score = (matches / total) * 10;
    }

    return score.clamp(0, 10);
  }

  // ── Save scored outfit to Firestore ──────────────────────────────
  static Future<void> saveOutfit({
    required String topId,
    required String bottomId,
    required String topImageUrl,
    required String bottomImageUrl,
    required String topColor,
    required String bottomColor,
    required String topStyle,
    required String bottomStyle,
    required OutfitScoreModel score,
    required double temperature,
    required String weatherCondition,
  }) async {
    print('🔵 ScoringService.saveOutfit() called');
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print('❌ No user authenticated!');
      throw Exception('User not authenticated. Please sign in.');
    }
    
    print('✅ User UID: $uid');
    print('📝 Preparing to save outfit data...');

    try {
      final outfitData = {
        'userId':         uid,
        'topId':          topId,
        'bottomId':       bottomId,
        'topImageUrl':    topImageUrl,
        'bottomImageUrl': bottomImageUrl,
        'topColor':       topColor,
        'bottomColor':    bottomColor,
        'topStyle':       topStyle,
        'bottomStyle':    bottomStyle,
        'totalScore':     score.totalScore,   // ← was 'score', now 'totalScore'
        'breakdown': {
          'colorHarmony':         score.colorHarmony,
          'styleConsistency':     score.styleConsistency,
          'formalityAlignment':   score.formalityAlignment,
          'weatherCompatibility': score.weatherCompatibility,
          'userPreferenceMatch':  score.userPreferenceMatch,
        },
        'explanation':      score.explanation,
        'temperature':      temperature,
        'weatherCondition': weatherCondition,
        'isFavorite':       false,            // ← was 'isFavorited', now 'isFavorite'
        'createdAt':        FieldValue.serverTimestamp(),
      };
      
      print('💾 Writing to Firestore: generated_outfits');
      await FirebaseFirestore.instance.collection('generated_outfits').add(outfitData);
      print('✅ Successfully saved to Firestore!');
    } catch (e) {
      print('❌ Firestore save failed: $e');
      rethrow;
    }
  }
}
