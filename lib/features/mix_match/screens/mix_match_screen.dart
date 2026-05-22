import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/outfit_score_model.dart';
import '../services/scoring_service.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/services/weather_service.dart';
import '../../../providers/weather_provider.dart' as app_weather;

// ── Wardrobe item (reuse or import from wardrobe_screen.dart) ────────

class _WardrobeItem {
  final String id;
  final String imageUrl;
  final String imageBase64;
  final String category;
  final String color;
  final String style;

  const _WardrobeItem({
    required this.id,
    required this.imageUrl,
    this.imageBase64 = '',
    required this.category,
    required this.color,
    required this.style,
  });

  factory _WardrobeItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return _WardrobeItem(
      id:       doc.id,
      imageUrl: d['imageUrl'] ?? '',
      imageBase64: d['imageBase64'] ?? '',
      category: d['category'] ?? '',
      color:    d['color'] ?? '',
      style:    d['style'] ?? '',
    );
  }
}

// ── Providers ────────────────────────────────────────────────────────

final _topsProvider = StreamProvider<List<_WardrobeItem>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('wardrobe_items')
      .where('userId', isEqualTo: uid)
      .where('category', isEqualTo: 'Top')
      .snapshots()
      .map((s) => s.docs.map(_WardrobeItem.fromFirestore).toList());
});

final _bottomsProvider = StreamProvider<List<_WardrobeItem>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('wardrobe_items')
      .where('userId', isEqualTo: uid)
      .where('category', isEqualTo: 'Bottom')
      .snapshots()
      .map((s) => s.docs.map(_WardrobeItem.fromFirestore).toList());
});

final _userPrefsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return {};
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (!doc.exists) return {};
  final d = doc.data()!;
  return {
    'favoriteColors':   List<String>.from(d['favoriteColors'] ?? []),
    'preferredStyles':  List<String>.from(d['preferredStyles'] ?? []),
  };
});

/*
final _unusedWeatherProvider = FutureProvider<dynamic>((ref) async {
  // Fetch weather by city — customize with user location or hardcode a city
  // Unused legacy weather provider kept disabled during the shared-provider migration.
  return null;
});
*/

// ── Screen ────────────────────────────────────────────────────────────

class MixMatchScreen extends ConsumerStatefulWidget {
  const MixMatchScreen({super.key});

  @override
  ConsumerState<MixMatchScreen> createState() => _MixMatchScreenState();
}

class _MixMatchScreenState extends ConsumerState<MixMatchScreen> {
  _WardrobeItem? _selectedTop;
  _WardrobeItem? _selectedBottom;
  OutfitScoreModel? _result;
  bool _scoring   = false;
  bool _saved     = false;
  String? _error;
  WeatherData? _weather;
  String? _selectedOccasion;

  static const Color _bg          = Color(0xFFF5F4F2);
  static const Color _ink         = Color(0xFF1A1814);
  static const Color _sand        = Color(0xFFC8C4BE);
  static const Color _muted       = Color(0xFF8A8784);
  static const Color _cardBg      = Color(0xFFFFFFFF);
  static const Color _border      = Color(0xFFE2E0DC);
  static const Color _borderStrong = Color(0xFFD8D6D2);
  static const Color _darkMuted   = Color(0xFF6B6862);

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final weatherState = ref.read(app_weather.weatherProvider);
      if (!weatherState.hasValue) {
        ref.read(app_weather.weatherProvider.notifier).fetchWeatherByLocation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topsAsync    = ref.watch(_topsProvider);
    final bottomsAsync = ref.watch(_bottomsProvider);
    final weatherAsync = ref.watch(app_weather.weatherProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: weatherAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: _ink, strokeWidth: 1)),
                error: (e, _) {
                  _weather = null; // Use fallback
                  return _buildContent(topsAsync, bottomsAsync);
                },
                data: (weather) {
                  _weather = weather;
                  return _buildContent(topsAsync, bottomsAsync);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AsyncValue<List<_WardrobeItem>> topsAsync, AsyncValue<List<_WardrobeItem>> bottomsAsync) {
    return topsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: _ink, strokeWidth: 1)),
      error: (e, _) => _buildError('Could not load wardrobe.'),
      data: (tops) => bottomsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: _ink, strokeWidth: 1)),
        error: (e, _) => _buildError('Could not load wardrobe.'),
        data: (bottoms) =>
            _buildBody(tops, bottoms),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _goBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _cardBg,
                border: Border.all(color: _border, width: 0.5),
              ),
              child: const Icon(Icons.arrow_back, size: 18, color: _ink),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OUTFIT STUDIO',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.0,
                        color: _muted)),
                const SizedBox(height: 4),
                Text('Mix & Match.',
                    style: GoogleFonts.cormorantGaramond(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        color: _ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      List<_WardrobeItem> tops, List<_WardrobeItem> bottoms) {
    final hasTop    = tops.isNotEmpty;
    final hasBottom = bottoms.isNotEmpty;

    if (!hasTop || !hasBottom) {
      return _buildEmptyState(hasTop, hasBottom);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Selectors ──
          Row(
            children: [
              Expanded(
                child: _buildSelector(
                  label: 'TOP',
                  selected: _selectedTop,
                  items: tops,
                  onTap: () => _openPicker(tops, isTop: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelector(
                  label: 'BOTTOM',
                  selected: _selectedBottom,
                  items: bottoms,
                  onTap: () => _openPicker(bottoms, isTop: false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Weather pill ──
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            color: _ink,
            child: Row(
              children: [
                const Icon(Icons.wb_sunny_outlined,
                    size: 13, color: _darkMuted),
                const SizedBox(width: 8),
                Text(
                    _weather != null
                        ? '${_weather!.condition} · ${_weather!.temperatureDisplay} — ${_weather!.cityName}, ${_weather!.country}'
                        : 'Loading weather...',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        letterSpacing: 1.0,
                        color: _darkMuted)),
              ],
            ),
          ),

const SizedBox(height: 20),

          // ── Occasion selector ──
          _buildOccasionSelector(),

          // ── Score button ──
          GestureDetector(
            onTap: (_selectedTop != null && _selectedBottom != null && !_scoring)
                ? _runScoring
                : null,
            child: Container(
              width: double.infinity,
              color: (_selectedTop != null && _selectedBottom != null)
                  ? _ink
                  : const Color(0xFF3A3834),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _scoring
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: _sand))
                    : Text('SCORE THIS OUTFIT',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2.2,
                            color: _sand)),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFAA4444),
                    fontWeight: FontWeight.w300)),
          ],

          // ── Result ──
          if (_result != null) ...[
            const SizedBox(height: 28),
            _buildDivider('SCORE RESULT'),
            const SizedBox(height: 14),
            _buildScoreBadge(_result!),
            const SizedBox(height: 14),
            _buildBreakdown(_result!),
            const SizedBox(height: 20),
            _buildDivider('AI ANALYSIS'),
            const SizedBox(height: 14),
            _buildExplanation(_result!),
            const SizedBox(height: 20),
            _buildSaveButton(),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Selector card ────────────────────────────────────────────────

  Widget _buildSelector({
    required String label,
    required _WardrobeItem? selected,
    required List<_WardrobeItem> items,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: _cardBg,
          border: Border.all(
              color: selected != null ? _ink : _border, width: 0.5),
        ),
        child: Stack(
          children: [
            if (selected != null)
              _itemImage(selected)
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 24, color: _muted),
                    const SizedBox(height: 6),
                    Text('SELECT $label',
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            letterSpacing: 1.4,
                            color: _muted)),
                  ],
                ),
              ),

            // Label badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                color: _ink,
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 8,
                        letterSpacing: 1.2,
                        color: _sand)),
              ),
            ),

            // Change badge if selected
            if (selected != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  color: _ink,
                  child: Text('CHANGE',
                      style: GoogleFonts.inter(
                          fontSize: 8,
                          letterSpacing: 1.2,
                          color: _sand)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _colorSwatch(String color) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _colorFromName(color),
      child: Center(
        child: Icon(Icons.checkroom_outlined,
            size: 32, color: Colors.white),
      ),
    );
  }

  Widget _itemImage(_WardrobeItem item) {
    if (item.imageBase64.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(item.imageBase64),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (_) {
        return _colorSwatch(item.color);
      }
    }

    if (item.imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => Container(color: _bg),
        errorWidget: (_, __, ___) => _colorSwatch(item.color),
      );
    }

    return _colorSwatch(item.color);
  }

  Color _colorFromName(String name) {
    return switch (name.toLowerCase()) {
      'black'  => const Color(0xFF1A1814),
      'white'  => const Color(0xFFF5F4F2),
      'gray'   => const Color(0xFF8A8784),
      'beige'  => const Color(0xFFC8C4BE),
      'brown'  => const Color(0xFF6B4423),
      'navy'   => const Color(0xFF1B2A4A),
      'blue'   => const Color(0xFF2E5FA3),
      'green'  => const Color(0xFF3A6B4A),
      'red'    => const Color(0xFF8B3A3A),
      'pink'   => const Color(0xFFE8A0A0),
      'yellow' => const Color(0xFFD4A843),
      'orange' => const Color(0xFFB8622A),
      'purple' => const Color(0xFF5C3D7A),
      _        => const Color(0xFFD8D6D2),
    };
  }

  // ── Score badge ──────────────────────────────────────────────────

  Widget _buildScoreBadge(OutfitScoreModel result) {
    final score = result.totalScore;
    final scoreColor = score >= 80
        ? const Color(0xFF2E8B57)
        : score >= 60
            ? const Color(0xFFB8860B)
            : const Color(0xFF8B3A3A);

    return Container(
      width: double.infinity,
      color: _ink,
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OUTFIT SCORE',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 1.8,
                      color: _darkMuted)),
              const SizedBox(height: 6),
              Text('${score.toStringAsFixed(0)}',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 64,
                      fontWeight: FontWeight.w300,
                      color: _sand,
                      height: 1)),
              Text('OUT OF 100',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 1.4,
                      color: _darkMuted)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            color: scoreColor,
            child: Text(
                score >= 80
                    ? 'STRONG\nMATCH'
                    : score >= 60
                        ? 'GOOD\nMATCH'
                        : 'WEAK\nMATCH',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                    color: Colors.white,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  // ── Breakdown ────────────────────────────────────────────────────

  Widget _buildBreakdown(OutfitScoreModel result) {
    final rows = [
      ('Colour Harmony',    result.colorHarmony,        '25%'),
      ('Style Consistency', result.styleConsistency,    '25%'),
      ('Formality',         result.formalityAlignment,  '20%'),
      ('Weather Match',     result.weatherCompatibility,'15%'),
      ('Preference Match',  result.userPreferenceMatch, '15%'),
    ];

    return Column(
      children: rows.map((r) {
        final pct = (r.$2 / 10 * 100).toInt();
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: _cardBg,
              border: Border.all(color: _border, width: 0.5)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.$1,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _ink)),
                    Text(r.$3,
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w300,
                            color: _muted)),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                child: LinearProgressIndicator(
                  value: r.$2 / 10,
                  backgroundColor: _bg,
                  valueColor: const AlwaysStoppedAnimation<Color>(_ink),
                  minHeight: 2,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 38,
                child: Text('$pct%',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _ink),
                    textAlign: TextAlign.right),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── AI Explanation ───────────────────────────────────────────────

  Widget _buildExplanation(OutfitScoreModel result) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: _cardBg,
          border: Border.all(color: _border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                color: _bg,
                child: const Center(
                    child: Icon(Icons.auto_awesome_outlined,
                        size: 14, color: _muted)),
              ),
              const SizedBox(width: 10),
              Text('AI ANALYSIS',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.8,
                      color: _muted)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
              result.explanation.isNotEmpty
                  ? result.explanation
                  : 'Generating analysis...',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: _ink,
                  height: 1.7)),
        ],
      ),
    );
  }

  // ── Save button ──────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saved ? null : _saveOutfit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _saved ? _bg : Colors.transparent,
          border: Border.all(
              color: _saved ? _border : _ink, width: 0.5),
        ),
        child: Center(
          child: Text(
              _saved ? 'SAVED TO OUTFITS' : 'SAVE THIS OUTFIT',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.0,
                  color: _saved ? _muted : _ink)),
        ),
      ),
    );
  }

// ── Occasion selector ───────────────────────────────────────────────

  Widget _buildOccasionSelector() {
    const occasions = ['Everyday', 'Work', 'Night Out', 'Travel', 'Gym'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDivider('OCCASION'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: occasions.map((o) {
            final selected = _selectedOccasion == o;
            return GestureDetector(
              onTap: () => setState(() => _selectedOccasion = o),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? _ink : _cardBg,
                  border: Border.all(
                      color: selected ? _ink : _borderStrong, width: 0.5),
                ),
                child: Text(o.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        color: selected ? _sand : _muted)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Empty state ──────────────────────────────────────────────────

  Widget _buildEmptyState(bool hasTop, bool hasBottom) {
    final title = !hasTop && !hasBottom
        ? 'Add two pieces.'
        : !hasTop
            ? 'Add a top.'
            : 'Add a bottom.';
    final message = !hasTop && !hasBottom
        ? 'Mix & Match needs at least one top and one bottom.'
        : !hasTop
            ? 'You already have a bottom. Add a top to create an outfit.'
            : 'You already have a top. Add a bottom to create an outfit.';

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
            const SizedBox(height: 20),
            Text(title,
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: _ink)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: _muted,
                    height: 1.6)),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => context.push('/add-wardrobe-item'),
              child: Container(
                color: _ink,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                child: Text('ADD MISSING ITEM',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.6,
                        color: _sand)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg) => Center(
      child: Text(msg,
          style: GoogleFonts.inter(
              fontSize: 13, color: _muted, fontWeight: FontWeight.w300)));

  Widget _buildDivider(String label) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 2.0,
                color: _muted)),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 0.5, color: _border)),
      ],
    );
  }

  // ── Picker sheet ─────────────────────────────────────────────────

  void _openPicker(List<_WardrobeItem> items, {required bool isTop}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        items: items,
        label: isTop ? 'TOP' : 'BOTTOM',
        onSelect: (item) {
          setState(() {
            if (isTop) {
              _selectedTop = item;
            } else {
              _selectedBottom = item;
            }
            _result = null;
            _saved  = false;
            _error  = null;
          });
        },
      ),
    );
  }

  // ── Scoring logic ─────────────────────────────────────────────────

  Future<void> _runScoring() async {
    if (_selectedTop == null || _selectedBottom == null || _weather == null) return;

    setState(() {
      _scoring = true;
      _result  = null;
      _error   = null;
      _saved   = false;
    });

    try {
      final prefs = await ref.read(_userPrefsProvider.future);
      final favoriteColors  = List<String>.from(prefs['favoriteColors']  ?? []);
      final preferredStyles = List<String>.from(prefs['preferredStyles'] ?? []);

// 1. Run deterministic scoring
      OutfitScoreModel score = await ScoringService.scoreOutfit(
        topColor:            _selectedTop!.color,
        topStyle:            _selectedTop!.style,
        bottomColor:         _selectedBottom!.color,
        bottomStyle:         _selectedBottom!.style,
        temperature:         _weather?.temperature ?? 28.0,
        weatherCondition:    _weather?.condition ?? 'Clear',
        userFavoriteColors:  favoriteColors,
        userPreferredStyles: preferredStyles,
        occasion:            _selectedOccasion ?? 'Everyday',
      );

      // 2. Generate AI explanation
      final explanation = await GroqService.generateExplanation(
        topColor:         _selectedTop!.color,
        topStyle:         _selectedTop!.style,
        bottomColor:      _selectedBottom!.color,
        bottomStyle:      _selectedBottom!.style,
        totalScore:       score.totalScore,
        colorScore:       score.colorHarmony,
        styleScore:       score.styleConsistency,
        formalityScore:  score.formalityAlignment,
        weatherScore:    score.weatherCompatibility,
        preferenceScore: score.userPreferenceMatch,
        weatherCondition: _weather?.condition ?? 'Clear',
        temperature:     _weather?.temperature ?? 28.0,
        occasion:        _selectedOccasion ?? 'Everyday',
      );

      score = score.copyWith(explanation: explanation);

      setState(() {
        _result  = score;
        _scoring = false;
      });
    } catch (e) {
      setState(() {
        _error   = 'Scoring failed. Please try again.';
        _scoring = false;
      });
    }
  }

  // ── Save to Firestore ─────────────────────────────────────────────

  Future<void> _saveOutfit() async {
    print('🔵 _saveOutfit() called');
    if (_result == null || _selectedTop == null || _selectedBottom == null || _weather == null) {
      print('❌ Missing data: result=$_result, top=$_selectedTop, bottom=$_selectedBottom, weather=$_weather');
      return;
    }

    try {
      print('💾 Calling ScoringService.saveOutfit()...');
      print('📊 Data: topId=${_selectedTop!.id}, topColor=${_selectedTop!.color}, topStyle=${_selectedTop!.style}');
      print('📊 Data: bottomId=${_selectedBottom!.id}, bottomColor=${_selectedBottom!.color}, bottomStyle=${_selectedBottom!.style}');
      print('📊 Score: ${_result!.totalScore}, Explanation: ${_result!.explanation.substring(0, 50)}...');
      
      await ScoringService.saveOutfit(
        topId:          _selectedTop!.id,
        bottomId:       _selectedBottom!.id,
        topImageUrl:    _selectedTop!.imageUrl,
        bottomImageUrl: _selectedBottom!.imageUrl,
        topColor:       _selectedTop!.color,
        bottomColor:    _selectedBottom!.color,
        topStyle:       _selectedTop!.style,
        bottomStyle:    _selectedBottom!.style,
        score:          _result!,
        temperature:    _weather!.temperature,
        weatherCondition: _weather!.condition,
      );
print('✅ Outfit saved successfully!');
      setState(() => _saved = true);
      
      // Navigate to outfits screen after saving
      if (mounted) {
        context.go('/outfits');
      }
    } catch (e, stackTrace) {
      print('❌ Error saving outfit: $e');
      print('📍 Stack trace: $stackTrace');
      setState(() => _error = 'Error: $e');
    }
  }
}

// ── Picker sheet ──────────────────────────────────────────────────────

class _PickerSheet extends StatelessWidget {
  final List<_WardrobeItem> items;
  final String label;
  final ValueChanged<_WardrobeItem> onSelect;

  const _PickerSheet({
    required this.items,
    required this.label,
    required this.onSelect,
  });

  static const Color _bg     = Color(0xFFF5F4F2);
  static const Color _ink    = Color(0xFF1A1814);
  static const Color _sand   = Color(0xFFC8C4BE);
  static const Color _muted  = Color(0xFF8A8784);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE2E0DC);
  static const Color _borderStrong = Color(0xFFD8D6D2);

  Color _colorFromName(String name) {
    return switch (name.toLowerCase()) {
      'black'  => const Color(0xFF1A1814),
      'white'  => const Color(0xFFF5F4F2),
      'gray'   => const Color(0xFF8A8784),
      'beige'  => const Color(0xFFC8C4BE),
      'brown'  => const Color(0xFF6B4423),
      'navy'   => const Color(0xFF1B2A4A),
      'blue'   => const Color(0xFF2E5FA3),
      'green'  => const Color(0xFF3A6B4A),
      'red'    => const Color(0xFF8B3A3A),
      'pink'   => const Color(0xFFE8A0A0),
      'yellow' => const Color(0xFFD4A843),
      'orange' => const Color(0xFFB8622A),
      'purple' => const Color(0xFF5C3D7A),
      _        => const Color(0xFFD8D6D2),
    };
  }

  Widget _itemImage(_WardrobeItem item) {
    final fallback = Container(
      color: _colorFromName(item.color),
      child: const Center(
        child: Icon(Icons.checkroom_outlined, size: 24, color: Colors.white),
      ),
    );

    if (item.imageBase64.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(item.imageBase64),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (_) {
        return fallback;
      }
    }

    if (item.imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => Container(color: _bg),
        errorWidget: (_, __, ___) => fallback,
      );
    }

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 32,
                  height: 2,
                  color: _borderStrong,
                  margin: const EdgeInsets.only(bottom: 24))),
          Text('SELECT $label',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.8,
                  color: _muted)),
          const SizedBox(height: 6),
          Text('Choose a piece.',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: _ink)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return GestureDetector(
                  onTap: () {
                    onSelect(item);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: _cardBg,
                        border: Border.all(color: _border, width: 0.5)),
                    child: Column(
                      children: [
                        Expanded(
                          child: _itemImage(item),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                              '${item.color} · ${item.style}'
                                  .toUpperCase(),
                              style: GoogleFonts.inter(
                                  fontSize: 8,
                                  letterSpacing: 0.8,
                                  color: _muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
