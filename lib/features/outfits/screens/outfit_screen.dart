import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/wardrobe_item_model.dart';
import '../services/wardrobe_service.dart';

// Pull in WardrobeItem from wardrobe_screen.dart (or a shared models file)
// import '../wardrobe/wardrobe_screen.dart';

// ─── Models ──────────────────────────────────────────────────────────

class ScoreBreakdown {
  final double colorHarmony;
  final double styleConsistency;
  final double formalityAlignment;
  final double weatherCompatibility;
  final double userPreferenceMatch;

  const ScoreBreakdown({
    required this.colorHarmony,
    required this.styleConsistency,
    required this.formalityAlignment,
    required this.weatherCompatibility,
    required this.userPreferenceMatch,
  });

  factory ScoreBreakdown.fromMap(Map<String, dynamic> m) => ScoreBreakdown(
        colorHarmony: (m['colorHarmony'] ?? 0).toDouble(),
        styleConsistency: (m['styleConsistency'] ?? 0).toDouble(),
        formalityAlignment: (m['formalityAlignment'] ?? 0).toDouble(),
        weatherCompatibility: (m['weatherCompatibility'] ?? 0).toDouble(),
        userPreferenceMatch: (m['userPreferenceMatch'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'colorHarmony': colorHarmony,
        'styleConsistency': styleConsistency,
        'formalityAlignment': formalityAlignment,
        'weatherCompatibility': weatherCompatibility,
        'userPreferenceMatch': userPreferenceMatch,
      };
}

class SavedOutfit {
  final String id;
  final String topId;
  final String bottomId;
  final String topImageUrl;
  final String bottomImageUrl;
  final String topColor;
  final String bottomColor;
  final String topStyle;
  final String bottomStyle;
  final double totalScore;
  final ScoreBreakdown breakdown;
  final String explanation;
  final String weatherCondition;
  final double temperature;
  final bool isFavorite;
  final DateTime createdAt;

  const SavedOutfit({
    required this.id,
    required this.topId,
    required this.bottomId,
    required this.topImageUrl,
    required this.bottomImageUrl,
    required this.topColor,
    required this.bottomColor,
    required this.topStyle,
    required this.bottomStyle,
    required this.totalScore,
    required this.breakdown,
    required this.explanation,
    required this.weatherCondition,
    required this.temperature,
    required this.isFavorite,
    required this.createdAt,
  });

  factory SavedOutfit.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    print('   📋 Raw Firestore data: $d');
    
    try {
      final breakdown = ScoreBreakdown.fromMap(d['breakdown'] ?? {});
      print('   ✅ Breakdown parsed: $breakdown');
      
      final outfit = SavedOutfit(
        id: doc.id,
        topId: d['topId'] ?? '',
        bottomId: d['bottomId'] ?? '',
        topImageUrl: d['topImageUrl'] ?? '',
        bottomImageUrl: d['bottomImageUrl'] ?? '',
        topColor: d['topColor'] ?? '',
        bottomColor: d['bottomColor'] ?? '',
        topStyle: d['topStyle'] ?? '',
        bottomStyle: d['bottomStyle'] ?? '',
        totalScore: (d['totalScore'] ?? 0).toDouble(),
        breakdown: breakdown,
        explanation: d['explanation'] ?? '',
        weatherCondition: d['weatherCondition'] ?? '',
        temperature: (d['temperature'] ?? 0).toDouble(),
        isFavorite: d['isFavorite'] ?? false,
        createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
      print('   ✅ SavedOutfit created successfully');
      return outfit;
    } catch (e) {
      print('   ❌ Error in SavedOutfit.fromFirestore: $e');
      rethrow;
    }
  }
}

// ─── Repository ──────────────────────────────────────────────────────

class OutfitsRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Stream<List<SavedOutfit>> watchOutfits() {
    final uid = _uid;
    if (uid == null) {
      print('❌ No user ID for watchOutfits()');
      return Stream.value([]);
    }
    
    print('🔵 watchOutfits() - uid=$uid');
    
    return _db
        .collection('generated_outfits')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          // Catch and log actual Firestore errors BEFORE map()
          print('❌ Firestore watchOutfits error: $error');
          throw error;
        })
        .map((snapshot) {
          print('📊 Snapshot received with ${snapshot.docs.length} documents');
          
          final outfits = snapshot.docs.map((doc) {
            try {
              print('📄 Parsing document: ${doc.id}');
              final outfit = SavedOutfit.fromFirestore(doc);
              print('✅ Parsed: ${outfit.topColor} + ${outfit.bottomColor}');
              return outfit;
            } catch (e) {
              print('❌ Error parsing outfit document ${doc.id}: $e');
              print('   Data: ${doc.data()}');
              return null;
            }
          })
          .whereType<SavedOutfit>()
          .toList();
          
          print('✅ Total outfits loaded: ${outfits.length}');
          return outfits;
        });
  }

  Future<void> toggleFavorite(String id, bool current) =>
      _db.collection('generated_outfits').doc(id).update({'isFavorite': !current});

  Future<void> deleteOutfit(String id) =>
      _db.collection('generated_outfits').doc(id).delete();
}

// ─── Providers ───────────────────────────────────────────────────────

final outfitsRepositoryProvider = Provider((_) => OutfitsRepository());

final outfitsStreamProvider = StreamProvider<List<SavedOutfit>>((ref) =>
    ref.watch(outfitsRepositoryProvider).watchOutfits());

final outfitsSortProvider = StateProvider<String>((ref) => 'Newest');
final outfitsFilterProvider = StateProvider<String>((ref) => 'All');

final filteredOutfitsProvider = Provider<AsyncValue<List<SavedOutfit>>>((ref) {
  final outfits = ref.watch(outfitsStreamProvider);
  final sort = ref.watch(outfitsSortProvider);
  final filter = ref.watch(outfitsFilterProvider);

  return outfits.whenData((list) {
    var result = list.where((o) {
      if (filter == 'Favourites') return o.isFavorite;
      if (filter == 'High Score') return o.totalScore >= 7.0;
      return true;
    }).toList();

    if (sort == 'Highest Score') {
      result.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    } else if (sort == 'Favourites') {
      result = result.where((o) => o.isFavorite).toList();
    }

    return result;
  });
});

// ─── Screen ──────────────────────────────────────────────────────────

class OutfitsScreen extends ConsumerWidget {
  const OutfitsScreen({super.key});

  static const _bg = Color(0xFFF5F4F2);
  static const _ink = Color(0xFF1A1814);
  static const _sand = Color(0xFFC8C4BE);
  static const _muted = Color(0xFF8A8784);
  static const _cardBg = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE2E0DC);
  static const _borderStrong = Color(0xFFD8D6D2);

  static const _filters = ['All', 'High Score', 'Favourites'];
  static const _sorts = ['Newest', 'Highest Score'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredOutfitsProvider);
    final activeFilter = ref.watch(outfitsFilterProvider);
    final activeSort = ref.watch(outfitsSortProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(ref, activeSort),
            _buildFilters(ref, activeFilter),
            Expanded(
              child: filtered.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: _ink, strokeWidth: 1)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('COULD NOT LOAD',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.8,
                                color: _muted)),
                        const SizedBox(height: 8),
                        Text(e.toString(),
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w300,
                                color: _muted,
                                height: 1.5),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        // Check if it's a Firestore index error
                        if (e.toString().contains('index') || 
                            e.toString().contains('FAILED_PRECONDITION'))
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: _ink,
                            child: Column(
                              children: [
                                Text(
                                    '⚠️ Missing Firestore Composite Index',
                                    style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                        color: _sand)),
                                const SizedBox(height: 8),
                                Text(
                                    'Create index in Firebase Console:\n\n'
                                    'Collection: generated_outfits\n'
                                    '• userId (Ascending)\n'
                                    '• createdAt (Descending)',
                                    style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w300,
                                        color: _sand,
                                        height: 1.6)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                data: (outfits) => outfits.isEmpty
                    ? _buildEmptyState(context)
                    : _buildList(context, ref, outfits),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, String activeSort) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OUTFIT HISTORY',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.0,
                      color: _muted)),
              const SizedBox(height: 4),
              Text('My Outfits.',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: _ink)),
            ],
          ),
          // Sort toggle
          GestureDetector(
            onTap: () => ref.read(outfitsSortProvider.notifier).state =
                activeSort == 'Newest' ? 'Highest Score' : 'Newest',
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: _cardBg,
                  border: Border.all(color: _border, width: 0.5)),
              child: Row(
                children: [
                  const Icon(Icons.sort, size: 14, color: _ink),
                  const SizedBox(width: 6),
                  Text(activeSort.toUpperCase(),
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          letterSpacing: 1.2,
                          color: _ink)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(WidgetRef ref, String active) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = _filters[i];
            final isActive = active == f;
            return GestureDetector(
              onTap: () =>
                  ref.read(outfitsFilterProvider.notifier).state = f,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? _ink : _cardBg,
                  border: Border.all(
                      color: isActive ? _ink : _borderStrong,
                      width: 0.5),
                ),
                child: Text(f.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w500,
                        color: isActive ? _sand : _muted)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<SavedOutfit> outfits) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      itemCount: outfits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _OutfitCard(
        outfit: outfits[i],
        onTap: () => _openDetail(context, outfits[i]),
        onFavorite: () => ref
            .read(outfitsRepositoryProvider)
            .toggleFavorite(outfits[i].id, outfits[i].isFavorite),
        onDelete: () => ref
            .read(outfitsRepositoryProvider)
            .deleteOutfit(outfits[i].id),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
                color: _cardBg,
                border: Border.all(color: _border, width: 0.5)),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  color: _bg,
                  child: const Center(
                      child: Icon(Icons.style_outlined,
                          size: 28, color: _muted)),
                ),
                const SizedBox(height: 20),
                Text('No outfits scored yet.',
                    style: GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: _ink)),
                const SizedBox(height: 8),
                Text(
                    'Head to Mix & Match, select a top and bottom, and score your first outfit combination.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: _muted,
                        height: 1.6)),
                const SizedBox(height: 20),
                Container(
                  color: _ink,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  child: Text('GO TO MIX & MATCH',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.0,
                          color: _sand)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...[
            ('01', 'Upload your wardrobe',
                'Add tops and bottoms from your camera or gallery.'),
            ('02', 'Select a combination',
                'Pick one top and one bottom in the Mix & Match studio.'),
            ('03', 'Get your score',
                'Ternova evaluates colour, style, weather, and your preferences.'),
          ].map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StepCard(step: t.$1, title: t.$2, body: t.$3),
              )),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, SavedOutfit outfit) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OutfitDetailScreen(outfit: outfit)),
    );
  }
}

// ─── Outfit Card ─────────────────────────────────────────────────────

class _OutfitCard extends StatelessWidget {
  final SavedOutfit outfit;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  const _OutfitCard({
    required this.outfit,
    required this.onTap,
    required this.onFavorite,
    required this.onDelete,
  });

  static const _bg = Color(0xFFF5F4F2);
  static const _ink = Color(0xFF1A1814);
  static const _muted = Color(0xFF8A8784);
  static const _cardBg = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE2E0DC);
  static const _sand = Color(0xFFC8C4BE);

  Color get _scoreColor {
    final s = outfit.totalScore * 10;
    if (s >= 80) return const Color(0xFF2E8B57);
    if (s >= 60) return const Color(0xFFB8860B);
    return const Color(0xFF8B3A3A);
  }

  @override
  Widget build(BuildContext context) {
    final score = (outfit.totalScore * 10).toStringAsFixed(0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: _cardBg,
            border: Border.all(color: _border, width: 0.5)),
        child: Column(
          children: [
            // Images row
            Row(
              children: [
                Expanded(child: _ClothingThumb(url: outfit.topImageUrl)),
                Container(width: 0.5, height: 140, color: _border),
                Expanded(child: _ClothingThumb(url: outfit.bottomImageUrl)),
              ],
            ),
            // Info row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${outfit.topColor} + ${outfit.bottomColor}'
                                    .toUpperCase(),
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.0,
                                    color: _ink)),
                            const SizedBox(height: 2),
                            Text(
                                '${outfit.topStyle} · ${outfit.bottomStyle}',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w300,
                                    color: _muted)),
                          ],
                        ),
                      ),
                      // Score badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        color: _scoreColor,
                        child: Text('$score',
                            style: GoogleFonts.cormorantGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                      height: 0.5,
                      color: _border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny_outlined,
                          size: 12, color: _muted),
                      const SizedBox(width: 4),
                      Text(
                          '${outfit.weatherCondition} · ${outfit.temperature.toStringAsFixed(0)}°',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w300,
                              color: _muted)),
                      const Spacer(),
                      GestureDetector(
                        onTap: onFavorite,
                        child: Icon(
                            outfit.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: outfit.isFavorite
                                ? _ink
                                : _muted),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline,
                            size: 16, color: _muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClothingThumb extends StatelessWidget {
  final String url;
  const _ClothingThumb({required this.url});

  static const _bg = Color(0xFFF5F4F2);
  static const _muted = Color(0xFF8A8784);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, __) => Container(
                  color: _bg,
                  child: const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 1, color: _muted))),
              errorWidget: (_, __, ___) => Container(
                  color: _bg,
                  child: const Center(
                      child: Icon(Icons.checkroom_outlined,
                          size: 24, color: _muted))),
            )
          : Container(
              color: _bg,
              child: const Center(
                  child: Icon(Icons.checkroom_outlined,
                      size: 24, color: _muted))),
    );
  }
}

// ─── Outfit Detail Screen ─────────────────────────────────────────────

class OutfitDetailScreen extends StatefulWidget {
  final SavedOutfit outfit;
  const OutfitDetailScreen({super.key, required this.outfit});

  @override
  State<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends State<OutfitDetailScreen> {
  bool _savingToWardrobe = false;

  static const _bg = Color(0xFFF5F4F2);
  static const _ink = Color(0xFF1A1814);
  static const _sand = Color(0xFFC8C4BE);
  static const _muted = Color(0xFF8A8784);
  static const _cardBg = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE2E0DC);

  Color get _scoreColor {
    final s = widget.outfit.totalScore * 10;
    if (s >= 80) return const Color(0xFF2E8B57);
    if (s >= 60) return const Color(0xFFB8860B);
    return const Color(0xFF8B3A3A);
  }

  @override
  Widget build(BuildContext context) {
    final score = (widget.outfit.totalScore * 10).toStringAsFixed(0);
    final b = widget.outfit.breakdown;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: _cardBg,
                          border: Border.all(color: _border, width: 0.5)),
                      child: const Icon(Icons.arrow_back,
                          size: 18, color: _ink),
                    ),
                  ),
                  const Spacer(),
                  Text('OUTFIT DETAIL',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.0,
                          color: _muted)),
                  const Spacer(),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Images + score
                    Container(
                      decoration: BoxDecoration(
                          color: _cardBg,
                          border: Border.all(color: _border, width: 0.5)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: _ClothingThumb(
                                      url: widget.outfit.topImageUrl)),
                              Container(
                                  width: 0.5, height: 180, color: _border),
                              Expanded(
                                  child: _ClothingThumb(
                                      url: widget.outfit.bottomImageUrl)),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${widget.outfit.topColor} + ${widget.outfit.bottomColor}'
                                              .toUpperCase(),
                                          style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 1.0,
                                              color: _ink)),
                                      Text(
                                          '${widget.outfit.topStyle} + ${widget.outfit.bottomStyle}',
                                          style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w300,
                                              color: _muted)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  color: _scoreColor,
                                  child: Text(score,
                                      style: GoogleFonts.cormorantGaramond(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Weather
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: _ink,
                      child: Row(
                        children: [
                          const Icon(Icons.wb_sunny_outlined,
                              size: 16, color: Color(0xFF6B6862)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('WEATHER AT TIME OF SCORING',
                                  style: GoogleFonts.inter(
                                      fontSize: 9,
                                      letterSpacing: 1.4,
                                      color: const Color(0xFF6B6862))),
                              const SizedBox(height: 4),
                              Text(
                                  '${widget.outfit.weatherCondition} · ${widget.outfit.temperature.toStringAsFixed(0)}°C',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w300,
                                      color: _sand)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Score breakdown
                    Text('SCORE BREAKDOWN',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2.0,
                            color: _muted)),
                    const SizedBox(height: 10),
                    ...[
                      ('Colour Harmony', b.colorHarmony, '25%'),
                      ('Style Consistency', b.styleConsistency, '25%'),
                      ('Formality Alignment', b.formalityAlignment, '20%'),
                      ('Weather Match', b.weatherCompatibility, '15%'),
                      ('Preference Match', b.userPreferenceMatch, '15%'),
                    ].map((t) => _ScoreRow(
                        label: t.$1, score: t.$2, weight: t.$3)),

                    const SizedBox(height: 16),

                    // AI Explanation
                    Container(
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
                              Text('OUTFIT ANALYSIS',
                                  style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.8,
                                      color: _muted)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                              widget.outfit.explanation.isNotEmpty
                                  ? widget.outfit.explanation
                                  : 'No explanation available.',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  color: _ink,
                                  height: 1.6)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Save to wardrobe button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: ElevatedButton(
                onPressed: _savingToWardrobe ? null : _saveOutfitToWardrobe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: _ink,
                  side: BorderSide(
                    color: _savingToWardrobe ? _border : _ink,
                    width: 0.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: _savingToWardrobe
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: _muted,
                        ),
                      )
                    : Text('SAVE OUTFIT TO WARDROBE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.0,
                          color: _ink,
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveOutfitToWardrobe() async {
    print('🔵 Button tapped! _savingToWardrobe=$_savingToWardrobe');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ User not authenticated');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to save to wardrobe')),
        );
      }
      return;
    }

    print('✅ User authenticated: ${user.uid}');

    if (!mounted) return;
    setState(() => _savingToWardrobe = true);

    try {
      print('🔄 Starting save process...');
      print('📊 Outfit data: top=${widget.outfit.topColor}, bottom=${widget.outfit.bottomColor}');
      print('🎨 Styles: top=${widget.outfit.topStyle}, bottom=${widget.outfit.bottomStyle}');
      print('🖼️ Images: top=${widget.outfit.topImageUrl.isNotEmpty}, bottom=${widget.outfit.bottomImageUrl.isNotEmpty}');
      
      final wardrobeService = WardrobeService();

      // Parse the style strings to enum values - with logging
      final topStyle = widget.outfit.topStyle.toLowerCase().trim();
      final bottomStyle = widget.outfit.bottomStyle.toLowerCase().trim();
      
      print('DEBUG: topStyle="$topStyle", bottomStyle="$bottomStyle"');

      final topStyleEnum = WardrobeStyleExtension.fromString(topStyle);
      final bottomStyleEnum = WardrobeStyleExtension.fromString(bottomStyle);

      print('DEBUG: topStyleEnum=$topStyleEnum, bottomStyleEnum=$bottomStyleEnum');

      // Save top to wardrobe
      print('💾 Saving top item...');
      await wardrobeService.addWardrobeItem(
        userId: user.uid,
        imageUrl: widget.outfit.topImageUrl,
        category: WardrobeCategory.top,
        color: widget.outfit.topColor,
        style: topStyleEnum,
      );

      print('✅ Top item saved successfully');

      // Save bottom to wardrobe
      print('💾 Saving bottom item...');
      await wardrobeService.addWardrobeItem(
        userId: user.uid,
        imageUrl: widget.outfit.bottomImageUrl,
        category: WardrobeCategory.bottom,
        color: widget.outfit.bottomColor,
        style: bottomStyleEnum,
      );

      print('✅ Bottom item saved successfully');
      print('🎉 All items saved!');

      if (mounted) {
        setState(() => _savingToWardrobe = false);
        print('✅ Items saved! Showing success message...');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Outfit saved to wardrobe!')),
        );
        print('🔄 Will redirect in 500ms...');
        Future.delayed(const Duration(milliseconds: 500), () {
          print('🔙 Redirecting back to previous screen...');
          if (mounted) {
            Navigator.pop(context);
            print('✅ Redirected!');
          }
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error saving to wardrobe: $e');
      print('📍 Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _savingToWardrobe = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double score;
  final String weight;
  const _ScoreRow(
      {required this.label, required this.score, required this.weight});

  static const _ink = Color(0xFF1A1814);
  static const _muted = Color(0xFF8A8784);
  static const _cardBg = Color(0xFFFFFFFF);
  static const _bg = Color(0xFFF5F4F2);
  static const _border = Color(0xFFE2E0DC);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: _cardBg, border: Border.all(color: _border, width: 0.5)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _ink)),
                Text(weight,
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w300,
                        color: _muted)),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: ClipRect(
              child: LinearProgressIndicator(
                value: score,
                backgroundColor: _bg,
                valueColor: const AlwaysStoppedAnimation<Color>(_ink),
                minHeight: 2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text('${(score * 100).toInt()}%',
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

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String body;
  const _StepCard(
      {required this.step, required this.title, required this.body});

  static const _ink = Color(0xFF1A1814);
  static const _muted = Color(0xFF8A8784);
  static const _cardBg = Color(0xFFFFFFFF);
  static const _bg = Color(0xFFF5F4F2);
  static const _border = Color(0xFFE2E0DC);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _cardBg, border: Border.all(color: _border, width: 0.5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            color: _bg,
            child: Center(
                child: Text(step,
                    style: GoogleFonts.cormorantGaramond(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: _muted))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _ink)),
                const SizedBox(height: 3),
                Text(body,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        color: _muted,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}