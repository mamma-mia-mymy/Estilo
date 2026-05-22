import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/outfit_providers.dart';
import '../models/weather_model.dart';

class MixMatchScreen extends ConsumerStatefulWidget {
  const MixMatchScreen({super.key});

  @override
  ConsumerState<MixMatchScreen> createState() => _MixMatchScreenState();
}

class _MixMatchScreenState extends ConsumerState<MixMatchScreen> {
  // ── All initState / providers / logic untouched ───────────────────
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(weatherProvider.notifier).fetchWeather();
    });
  }

  static const Color _bg          = Color(0xFFF5F4F2);
  static const Color _ink         = Color(0xFF1A1814);
  static const Color _sand        = Color(0xFFC8C4BE);
  static const Color _muted       = Color(0xFF8A8784);
  static const Color _cardBg      = Color(0xFFFFFFFF);
  static const Color _border      = Color(0xFFE2E0DC);
  static const Color _borderStrong = Color(0xFFD8D6D2);
  static const Color _darkPanel   = Color(0xFF252320);
  static const Color _darkBorder  = Color(0xFF2E2C28);
  static const Color _darkMuted   = Color(0xFF6B6862);

  // ── build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final wardrobeState = ref.watch(wardrobeProvider);
    final weatherState  = ref.watch(weatherProvider);
    final weather       = weatherState.weather;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildBody(wardrobeState, weather)),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _cardBg,
                  border: Border.all(color: _borderStrong, width: 0.5)),
              child: const Icon(Icons.arrow_back, size: 16, color: _ink),
            ),
          ),
          Text('OUTFIT STUDIO',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.0,
                  color: _muted)),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  // ── Body router (functionality unchanged) ─────────────────────────

  Widget _buildBody(WardrobeState wardrobeState, WeatherModel? weather) {
    if (wardrobeState.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: _ink, strokeWidth: 1));
    }
    if (!wardrobeState.hasEnoughItems) {
      return _buildEmptyState(wardrobeState);
    }
    return _buildContent(wardrobeState, weather);
  }

  // ── Empty state ───────────────────────────────────────────────────

  Widget _buildEmptyState(WardrobeState wardrobeState) {
    String message;
    if (wardrobeState.tops.isEmpty && wardrobeState.bottoms.isEmpty) {
      message = 'Upload at least one top and one bottom to generate outfits.';
    } else if (wardrobeState.tops.isEmpty) {
      message = 'Add some tops to start generating outfit combinations.';
    } else {
      message = 'Add some bottoms to start generating outfit combinations.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              color: _cardBg,
              child: const Center(
                  child: Icon(Icons.checkroom_outlined,
                      size: 32, color: _muted)),
            ),
            const SizedBox(height: 24),
            Text('WARDROBE INCOMPLETE',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.8,
                    color: _muted)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: _muted,
                    height: 1.6)),
            const SizedBox(height: 20),
            Text(
                '${wardrobeState.tops.length} tops  ·  '
                '${wardrobeState.bottoms.length} bottoms',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: _ink)),
          ],
        ),
      ),
    );
  }

  // ── Content (all scoring logic untouched) ─────────────────────────

  Widget _buildContent(WardrobeState wardrobeState, WeatherModel? weather) {
    final generatorService  = ref.read(outfitGeneratorServiceProvider);
    final scorerService     = ref.read(outfitScorerServiceProvider);
    final currentWeather    = weather ?? WeatherModel.placeholder();

    scoreCalculator(top, bottom) => scorerService.calculateScore(
          top: top,
          bottom: bottom,
          weather: currentWeather,
        );

    final combinations = generatorService.generateCombinations(
      tops: wardrobeState.tops,
      bottoms: wardrobeState.bottoms,
      scoreCalculator: scoreCalculator,
    );

    final bestOutfit         = generatorService.findBestOutfit(combinations);
    final topRecommendations = generatorService.getTopRecommendations(
      combinations: combinations,
      count: 5,
    );

    if (bestOutfit == null) return _buildEmptyState(wardrobeState);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero text
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.cormorantGaramond(
                        fontSize: 44,
                        fontWeight: FontWeight.w400,
                        color: _ink,
                        height: .95),
                    children: const [
                      TextSpan(text: 'Mix &\n'),
                      TextSpan(
                          text: 'Match.',
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF8A8784))),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: Container(
                            height: 0.5, color: _borderStrong)),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('BEST COMBINATION',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              letterSpacing: 1.4,
                              color: _muted)),
                    ),
                    Expanded(
                        child: Container(
                            height: 0.5, color: _borderStrong)),
                  ],
                ),
              ],
            ),
          ),

          // Weather bar
          _buildWeatherSummary(currentWeather),

          // Dark outfit stage
          _buildOutfitStage(bestOutfit),

          // Recommendations
          _buildRecommendationsList(topRecommendations),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Weather summary ───────────────────────────────────────────────

  Widget _buildWeatherSummary(WeatherModel weather) {
    return Container(
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFD8D6D2), width: 0.5),
        ),
      ),
      margin: const EdgeInsets.only(top: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Temp block
            Container(
              color: _ink,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(weather.temperatureDisplay,
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          color: _sand,
                          height: 1)),
                ],
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(weather.condition,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: _ink)),
                    const SizedBox(height: 2),
                    Text('${weather.cityName}, ${weather.country}',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            color: _muted)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: _border, width: 0.5)),
                      child: Text(weather.weatherAdvice.toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 8,
                              letterSpacing: 1.4,
                              color: _muted)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Outfit stage — the hero dark block ────────────────────────────

  Widget _buildOutfitStage(dynamic bestOutfit) {
    final score      = bestOutfit.totalScore * 10;
    final breakdown  = bestOutfit.scoreBreakdown;

    return Container(
      color: _ink,
      child: Stack(
        children: [
          // Watermark score number
          Positioned(
            right: -8,
            bottom: 60,
            child: Text(
              score.toStringAsFixed(0),
              style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 130,
                  fontWeight: FontWeight.w300,
                  color: const Color(0x07C8C4BE),
                  height: 1),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label + score badge
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('BEST OUTFIT TODAY',
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.8,
                            color: _darkMuted)),
                    // Score badge
                    Container(
                      color: _sand,
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      child: Column(
                        children: [
                          Text(score.toStringAsFixed(0),
                              style: GoogleFonts.cormorantGaramond(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w400,
                                  color: _ink,
                                  height: 1)),
                          Text('/ 100',
                              style: GoogleFonts.inter(
                                  fontSize: 8,
                                  letterSpacing: 1.2,
                                  color: const Color(0xFF4A4844))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Side-by-side outfit images
              Row(
                children: [
                  Expanded(
                    child: _buildClothingImage(
                        bestOutfit.top.imageUrl,
                        bestOutfit.top.color,
                        'TOP'),
                  ),
                  Container(
                      width: 1, height: 200, color: _darkBorder),
                  Expanded(
                    child: _buildClothingImage(
                        bestOutfit.bottom.imageUrl,
                        bestOutfit.bottom.color,
                        'BOTTOM'),
                  ),
                ],
              ),

              // Score breakdown inside the dark stage
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Column(
                  children: [
                    Container(
                        height: 0.5,
                        color: _darkBorder,
                        margin: const EdgeInsets.only(bottom: 14)),
                    _buildDarkScoreRow(
                        'Colour Harmony',
                        breakdown.colorHarmony),
                    _buildDarkScoreRow(
                        'Style Consistency',
                        breakdown.styleConsistency),
                    _buildDarkScoreRow(
                        'Weather Fit',
                        breakdown.weatherCompatibility),
                    _buildDarkScoreRow(
                        'Formality',
                        breakdown.formalityAlignment),
                    _buildDarkScoreRow(
                        'Preference',
                        breakdown.userPreferenceMatch),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDarkScoreRow(String label, double score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    letterSpacing: .04,
                    color: _darkMuted)),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: _darkBorder,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: score.clamp(0.0, 1.0),
                  child: Container(height: 1, color: _sand),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            child: Text('${(score * 100).toInt()}%',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    color: _darkMuted),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  // ── Clothing image (logic untouched) ──────────────────────────────

  Widget _buildClothingImage(
      String imageUrl, String color, String label) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                        color: _darkPanel,
                        child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 1, color: _sand))),
                    errorWidget: (context, url, error) => Container(
                      color: _darkPanel,
                      child: const Center(
                          child: Icon(Icons.checkroom_outlined,
                              size: 32, color: Color(0xFF3A3834))),
                    ),
                  )
                : Container(
                    color: _darkPanel,
                    child: const Center(
                        child: Icon(Icons.checkroom_outlined,
                            size: 32, color: Color(0xFF3A3834))),
                  ),
          ),
          // Label badge bottom-left
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              color: _ink,
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 8,
                      letterSpacing: 1.4,
                      color: _darkMuted)),
            ),
          ),
          // Color bottom-right
          Positioned(
            bottom: 10,
            right: 10,
            child: Text(color.toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.0,
                    color: _darkMuted)),
          ),
        ],
      ),
    );
  }

  // ── Recommendations list ──────────────────────────────────────────

  Widget _buildRecommendationsList(outfits) {
    final list = outfits.skip(1).take(4).toList();
    if (list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Other Combinations',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: _ink)),
              Text('${list.length} MORE',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.4,
                      color: _muted)),
            ],
          ),
          const SizedBox(height: 16),
          ...list.asMap().entries.map((e) =>
              _buildRecRow(e.value, e.key + 2)),
        ],
      ),
    );
  }

  Widget _buildRecRow(dynamic outfit, int rank) {
    final score = outfit.totalScore * 10;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E0DC), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 22,
            child: Text('$rank',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: _borderStrong,
                    height: 1)),
          ),
          const SizedBox(width: 10),

          // Two thumbnails
          _RecThumb(imageUrl: outfit.top.imageUrl),
          const SizedBox(width: 4),
          _RecThumb(imageUrl: outfit.bottom.imageUrl),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${outfit.top.color} + ${outfit.bottom.color}',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _ink)),
                const SizedBox(height: 2),
                Text(
                    '${outfit.top.style.displayName} · '
                    '${outfit.bottom.style.displayName}',
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w300,
                        color: _muted)),
              ],
            ),
          ),

          // Score
          Text(score.toStringAsFixed(0),
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: _ink,
                  height: 1)),
        ],
      ),
    );
  }
}

// ── Recommendation thumbnail ──────────────────────────────────────────

class _RecThumb extends StatelessWidget {
  final String imageUrl;
  const _RecThumb({required this.imageUrl});

  static const Color _bg   = Color(0xFFF5F4F2);
  static const Color _muted = Color(0xFF8A8784);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: _bg,
      child: imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const Icon(
                  Icons.checkroom_outlined,
                  size: 18,
                  color: _muted),
            )
          : const Icon(Icons.checkroom_outlined, size: 18, color: _muted),
    );
  }
}

// ── Score breakdown card (kept for backwards compatibility) ───────────

// ignore: unused_element
class _ScoreCard extends StatelessWidget {
  final String label;
  final double score;
  final String weight;

  const _ScoreCard({
    required this.label,
    required this.score,
    required this.weight,
  });

  static const Color _bg     = Color(0xFFF5F4F2);
  static const Color _ink    = Color(0xFF1A1814);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE2E0DC);

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).toInt();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _cardBg,
          border: Border.all(color: _border, width: 0.5)),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: _ink)),
                const SizedBox(height: 4),
                Text(weight,
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF8A8784))),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: _bg,
              valueColor: const AlwaysStoppedAnimation<Color>(_ink),
              minHeight: 2,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text('$percentage%',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _ink),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

