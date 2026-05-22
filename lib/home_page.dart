import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/outfits/screens/wardrobe_screen.dart';
import 'features/outfits/screens/outfit_screen.dart';
import 'features/outfits/screens/profile_screen.dart';
import 'providers/weather_provider.dart';
import 'providers/wardrobe_stats_provider.dart';
import 'providers/profile_provider.dart';

// ── User name provider ────────────────────────────────────────────────────────
final _userNameProvider = StreamProvider<String>((ref) async* {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    yield 'there';
    return;
  }
  
  // First yield cached/default value immediately
  yield 'there';
  
  // Then listen for real-time updates from Firestore
  await for (final doc in FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()) {
    final name = doc.data()?['name'] ?? doc.data()?['fullName'] ?? '';
    yield name.isNotEmpty ? name.split(' ').first : 'there';
  }
});

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;
  String? _selectedOccasion;

  static const Color _bg          = Color(0xFFF5F4F2);
  static const Color _ink         = Color(0xFF1A1814);
  static const Color _sand        = Color(0xFFC8C4BE);
  static const Color _muted       = Color(0xFF8A8784);
  static const Color _cardBg      = Color(0xFFFFFFFF);
  static const Color _border      = Color(0xFFE2E0DC);
  static const Color _borderStrong = Color(0xFFD8D6D2);
  static const Color _darkMuted   = Color(0xFF6B6862);
  static const Color _darkest     = Color(0xFF252320);

static const List<Map<String, dynamic>> _categories = [
    {'label': 'Formal',      'icon': Icons.business_center_outlined},
    {'label': 'Everyday',   'icon': Icons.weekend_outlined},
    {'label': 'Streetwear','icon': Icons.skateboarding_outlined},
    {'label': 'Vintage',   'icon': Icons.auto_awesome_outlined},
  ];

@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch weather data
      ref.read(weatherProvider.notifier).fetchWeatherByLocation();
      
      // Load user profile to ensure name is available
      _loadUserProfile();
    });
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    try {
      // Load profile into the profileProvider state
      await ref.read(profileProvider.notifier).loadProfile(uid);
    } catch (e) {
      // Silently handle error - the StreamProvider will still work
    }
  }

  void _onTabTap(int index) {
    if (index == 2) {
      _showUploadSheet();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _showUploadSheet() {
    context.push('/creation-hub');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeBody(),
            const WardrobeScreen(),
            const SizedBox(),
            const OutfitsScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Home body ───────────────────────────────────────────────────────

Widget _buildHomeBody() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSplitHero(),
                _buildWeatherBar(),
                _buildWeatherSuggestion(),
                _buildScoreCta(),
                _buildWardrobeScroll(),
                _buildOccasionGrid(),
                _buildStatsBar(),
                _buildTipQuote(),
                _buildUploadPrompt(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('TERNOVA',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3.5,
                  color: _ink)),
          Row(
            children: [
              _IconBtn(icon: Icons.notifications_none_outlined),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                color: _ink,
                child: Center(
                  child: Text('K',
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _sand)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Split hero ──────────────────────────────────────────────────────

Widget _buildSplitHero() {
    final now          = DateTime.now();
    final day         = now.day.toString();
    final months     = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
    final month      = months[now.month - 1];
    final year       = now.year.toString();
    final userNameAsync = ref.watch(_userNameProvider);
    final userName    = userNameAsync.maybeWhen(
        data: (n) => n, orElse: () => 'there');

    return Container(
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFD8D6D2), width: 0.5),
        ),
      ),
      margin: const EdgeInsets.only(top: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left — greeting
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFD8D6D2), width: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GOOD MORNING',
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2.0,
                            color: _muted)),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.cormorantGaramond(
                            fontSize: 36,
                            fontWeight: FontWeight.w400,
                            color: _ink,
                            height: 1.0),
children: [
                          TextSpan(text: 'Hello,\n'),
                          TextSpan(
text: userName,
                            style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF8A8784)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                        'Your wardrobe is waiting.\nWhat are you wearing today?',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: _muted,
                            height: 1.5)),
                  ],
                ),
              ),
            ),

            // Right — date block
            Container(
              color: _ink,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(day,
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 52,
                          fontWeight: FontWeight.w300,
                          color: _sand,
                          height: 1)),
                  const SizedBox(height: 4),
                  Text(month,
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.8,
                          color: _darkMuted)),
                  Text(year,
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.2,
                          color: const Color(0xFF4A4844))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Weather bar ─────────────────────────────────────────────────────

  Widget _buildWeatherBar() {
    final weatherState = ref.watch(weatherProvider);

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFD8D6D2), width: 0.5),
        ),
      ),
      child: weatherState.when(
        loading: () => _weatherBarContent(
            temp: '—', condition: 'Loading...', city: '', advice: ''),
        error: (_, __) => _weatherBarContent(
            temp: '—', condition: 'Unavailable', city: '', advice: ''),
        data: (w) {
          if (w == null) {
            return _weatherBarContent(
                temp: '—', condition: 'Unavailable', city: '', advice: '');
          }
          return _weatherBarContent(
            temp:      w.temperature.toStringAsFixed(0),
            condition: w.condition,
            city:      '${w.cityName}, ${w.country}',
            advice:    w.weatherAdvice,
          );
        },
      ),
    );
  }

  Widget _weatherBarContent({
    required String temp,
    required String condition,
    required String city,
    required String advice,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Temp block — dark
          Container(
            color: _ink,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(temp,
                    style: GoogleFonts.cormorantGaramond(
                        fontSize: 38,
                        fontWeight: FontWeight.w300,
                        color: _sand,
                        height: 1)),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text('°',
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: _darkMuted)),
                ),
              ],
            ),
          ),

          // Info block
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(condition,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: _ink)),
                  const SizedBox(height: 2),
                  if (city.isNotEmpty)
                    Text(city,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            color: _muted)),
                  if (advice.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          border: Border.all(color: _border, width: 0.5)),
                      child: Text(advice.toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 8,
                              letterSpacing: 1.4,
                              color: _muted)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Score CTA ───────────────────────────────────────────────────────

  Widget _buildScoreCta() {
    final wardrobeStats = ref.watch(wardrobeStatsProvider);

    return wardrobeStats.when(
      loading: () => _scoreCTAContent(canAct: false),
      error:   (_, __) => _scoreCTAContent(canAct: false),
      data:    (stats) => _scoreCTAContent(
          canAct: stats.topsCount > 0 && stats.bottomsCount > 0),
    );
  }

  Widget _scoreCTAContent({required bool canAct}) {
    return Stack(
      children: [
        Positioned(
          left: -8,
          top: -10,
          child: Text('Score',
              style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 140,
                  fontWeight: FontWeight.w300,
                  color: const Color(0x0D1A1814),
                  height: 1)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MIX & MATCH',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.0,
                      color: _muted)),
              const SizedBox(height: 12),
              Text('Rate today\'s\noutfit.',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 42,
                      fontWeight: FontWeight.w400,
                      color: _ink,
                      height: 1.0)),
              const SizedBox(height: 6),
              Text(
                  canAct
                      ? 'Pick pieces from your wardrobe. Get a score.'
                      : 'Upload at least one top and bottom to begin.',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: _muted)),
              const SizedBox(height: 20),
              Row(
                children: [
                  GestureDetector(
                    onTap: canAct
                        ? () => context.push('/mix-match')
                        : null,
                    child: Container(
                      color: canAct ? _ink : _borderStrong,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      child: Text('START SCORING',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2.0,
                              color: canAct ? _sand : _muted)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showUploadSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: _borderStrong, width: 0.5)),
                      child: Text('UPLOAD FIRST',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.4,
                              color: _muted)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Wardrobe horizontal scroll ──────────────────────────────────────

  Widget _buildWardrobeScroll() {
    final wardrobeStats = ref.watch(wardrobeStatsProvider);

    final counts = wardrobeStats.maybeWhen(
      data: (s) => [s.topsCount, s.bottomsCount, 0, 0],
      orElse: () => [0, 0, 0, 0],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('My Wardrobe',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: _ink)),
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 1),
                child: Text('VIEW ALL',
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.6,
                        color: _muted,
                        decoration: TextDecoration.underline,
                        decorationColor: _muted)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 138,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final cat   = _categories[i];
              final count = i < counts.length ? counts[i] : 0;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = 1),
                child: Container(
                  width: 110,
                  decoration: BoxDecoration(
                      color: _cardBg,
                      border: Border.all(color: _border, width: 0.5)),
                  child: Column(
                    children: [
                      Container(
                        height: 80,
                        color: _bg,
                        child: Center(
                            child: Icon(
                                cat['icon'] as IconData,
                                size: 26,
                                color: const Color(0xFFC8C4BE))),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                (cat['label'] as String).toUpperCase(),
                                style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.2,
                                    color: _ink)),
                            const SizedBox(height: 2),
                            Text('$count items',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w300,
                                    color: _muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Occasion grid ───────────────────────────────────────────────────

  Widget _buildOccasionGrid() {
    final wardrobeStats = ref.watch(wardrobeStatsProvider);

    const occasions = [
      ('Everyday', 'Casual day out',       '01'),
      ('Work',     'Professional setting', '02'),
      ('Night Out','Evening events',        '03'),
      ('Travel',   'On the move',          '04'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("WHAT'S THE OCCASION?",
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.0,
                  color: _muted)),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: occasions.asMap().entries.map((entry) {
              final occ        = entry.value;
              final isSelected = _selectedOccasion == occ.$1;
              final isDark     = isSelected;

              return GestureDetector(
                onTap: () => setState(() => _selectedOccasion == occ.$1
                    ? _selectedOccasion = null
                    : _selectedOccasion = occ.$1),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  decoration: BoxDecoration(
                    color: isDark ? _ink : _cardBg,
                    border: Border.all(
                        color: isDark ? _ink : _border, width: 0.5),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 0,
                        bottom: -4,
                        child: Text(occ.$3,
                            style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 32,
                                fontWeight: FontWeight.w300,
                                color: isDark
                                    ? const Color(0xFF252320)
                                    : const Color(0xFFE2E0DC),
                                height: 1)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(occ.$1.toUpperCase(),
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.4,
                                  color: isDark ? _sand : _ink)),
                          const SizedBox(height: 4),
                          Text(occ.$2,
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w300,
                                  color: isDark ? _darkMuted : _muted)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Score button — reacts to stats + occasion selection
          wardrobeStats.when(
            loading: () => _scoreBtn(active: false),
            error:   (_, __) => _scoreBtn(active: false),
            data: (stats) {
              final canScore = stats.topsCount > 0 &&
                  stats.bottomsCount > 0 &&
                  _selectedOccasion != null;
              return GestureDetector(
                onTap: canScore
                    ? () => context.push('/mix-match')
                    : null,
                child: _scoreBtn(active: canScore),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _scoreBtn({required bool active}) {
    return Container(
      width: double.infinity,
      color: active ? _ink : _borderStrong,
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Center(
        child: Text('SCORE MY OUTFIT',
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 2.2,
                color: active ? _sand : _muted)),
      ),
    );
  }

  // ── Stats bar ───────────────────────────────────────────────────────

  Widget _buildStatsBar() {
    final wardrobeStats = ref.watch(wardrobeStatsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(color: _border, width: 0.5)),
        child: IntrinsicHeight(
          child: Row(
            children: wardrobeStats.when(
              loading: () => _statCells('—', '—', '—'),
              error:   (_, __) => _statCells('0', '0', '—'),
              data:    (s) => _statCells('${s.totalCount}', '0', '—'),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _statCells(String pieces, String outfits, String avg) {
    final items = [
      (pieces,  'Pieces'),
      (outfits, 'Outfits'),
      (avg,     'Avg Score'),
    ];
    return items.asMap().entries.map((e) {
      final isLast = e.key == items.length - 1;
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: _cardBg,
            border: Border(
              right: isLast
                  ? BorderSide.none
                  : const BorderSide(
                      color: Color(0xFFE2E0DC), width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.value.$1,
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: _ink,
                      height: 1)),
              const SizedBox(height: 3),
              Text(e.value.$2.toUpperCase(),
                  style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.4,
                      color: _muted)),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── Tip quote ───────────────────────────────────────────────────────

  Widget _buildTipQuote() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFF1A1814), width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STYLE TIP',
              style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.8,
                  color: _muted)),
          const SizedBox(height: 6),
          Text(
              '"Neutral tones pair with almost anything. Start your wardrobe with beige, white, and charcoal."',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: _ink,
                  height: 1.4)),
        ],
      ),
    );
  }

  // ── Upload prompt ───────────────────────────────────────────────────

  Widget _buildUploadPrompt() {
    return GestureDetector(
      onTap: _showUploadSheet,
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        color: _ink,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ADD TO WARDROBE',
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.8,
                        color: _darkMuted)),
                const SizedBox(height: 6),
                Text('Your closet\nawaits.',
                    style: GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: _sand,
                        height: 1.1)),
              ],
            ),
            Container(
              color: _sand,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 11),
              child: Text('UPLOAD NOW',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.8,
                      color: _ink)),
            ),
          ],
        ),
      ),
    );
  }

// ── Weather suggestion card ────────────────────────────────────────────

  Widget _buildWeatherSuggestion() {
    final weatherState = ref.watch(weatherProvider);

    return weatherState.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (w) {
        if (w == null) return const SizedBox.shrink();
        final advice = _getWeatherOutfitAdvice(
          temperature: w.temperature,
          condition:   w.condition,
        );
        return _WeatherSuggestionCard(
          temperature: w.temperature,
          condition:   w.condition,
          advice:      advice,
        );
      },
    );
  }

  /// Returns structured outfit advice based on real temperature + condition
  _WeatherAdvice _getWeatherOutfitAdvice({
    required double temperature,
    required String condition,
  }) {
    final cond = condition.toLowerCase();
    final isRain  = cond.contains('rain') || cond.contains('drizzle') || cond.contains('shower');
    final isCloud = cond.contains('cloud') || cond.contains('overcast');
    final isClear = cond.contains('clear') || cond.contains('sunny');
    final isWind  = cond.contains('wind');

    if (temperature >= 34) {
      return const _WeatherAdvice(
        tag:        'VERY HOT',
        headline:   'Keep it light.',
        body:       'At this temperature, opt for breathable fabrics — linen, cotton, or loose weaves. Light colours like white, beige, and pastels will reflect heat. Avoid dark colours and layering entirely.',
        avoid:      'Heavy fabrics · Dark colours · Layering',
        recommend:  'Linen tops · Lightweight cottons · Loose silhouettes',
      );
    }

    if (temperature >= 29) {
      if (isRain) {
        return const _WeatherAdvice(
          tag:       'HOT & RAINY',
          headline:  'Light but rain-ready.',
          body:      'It\'s warm and wet — go for lightweight waterproof or quick-dry fabrics. Avoid cotton that gets heavy when wet. A minimal rain jacket over a light top works well.',
          avoid:     'Heavy cotton · Light-coloured bottoms · Suede',
          recommend: 'Quick-dry fabrics · Dark bottoms · Minimal rain layer',
        );
      }
      return const _WeatherAdvice(
        tag:       'HOT',
        headline:  'Breathable and minimal.',
        body:      'Stick to one light layer. Casual and minimalist styles work best here — loose fits in neutral or light tones. This is not the day for formal heavy pieces.',
        avoid:     'Heavy layers · Dark fabrics · Tight fits',
        recommend: 'Light neutrals · Casual or minimalist style · Breathable cuts',
      );
    }

    if (temperature >= 24) {
      if (isRain) {
        return const _WeatherAdvice(
          tag:       'WARM & RAINY',
          headline:  'Layer smart.',
          body:      'A warm rainy day calls for a light waterproof layer over your outfit. Avoid fabrics that get heavy when wet. A structured top with waterproof outerwear keeps you looking put-together.',
          avoid:     'Suede · White bottoms · Open shoes',
          recommend: 'Waterproof jacket · Dark bottoms · Structured top',
        );
      }
      return const _WeatherAdvice(
        tag:       'WARM',
        headline:  'Comfortable and put-together.',
        body:      'The sweet spot for most outfits. Any casual, minimalist, or smart-casual combination works. You can do one light layer without overheating.',
        avoid:     'Heavy outerwear · Very dark all-over looks',
        recommend: 'Any style works well · Light layer optional · Neutrals or colour both fine',
      );
    }

    if (temperature >= 18) {
      if (isRain) {
        return const _WeatherAdvice(
          tag:       'COOL & RAINY',
          headline:  'Layer up, stay dry.',
          body:      'Cool and wet — you need at least two layers. A base top with a structured jacket or coat is ideal. Darker colours hide rain spots better.',
          avoid:     'Single layers · Light-coloured outerwear · Suede anything',
          recommend: 'Structured jacket · Dark or mid-tone palette · Covered footwear',
        );
      }
      return const _WeatherAdvice(
        tag:       'MILD',
        headline:  'Perfect layering weather.',
        body:      'This is the best temperature range for outfit creativity. You can layer without overheating — a top with a light jacket or overshirt works great. Most styles pull off well here.',
        avoid:     'Nothing really — all styles work',
        recommend: 'Layered looks · Any style · Jacket or overshirt optional',
      );
    }

    if (temperature >= 12) {
      return const _WeatherAdvice(
        tag:       'COOL',
        headline:  'Layers are your friend.',
        body:      'It\'s getting cool — commit to layering. A base layer with a mid-layer like a knit or jacket is the move. Formal and vintage styles work particularly well in this range.',
        avoid:     'Single light layers · Shorts · Sandals',
        recommend: 'Knits · Structured jackets · Formal or vintage aesthetic',
      );
    }

    // Below 12°C
    return const _WeatherAdvice(
      tag:       'COLD',
      headline:  'Bundle up properly.',
      body:      'Cold weather calls for serious layering. Start with a warm base, add a mid-layer, and finish with a coat or heavy outerwear. Dark, rich tones like navy, brown, and black read well in cold weather.',
      avoid:     'Light fabrics · Minimal layers · Casual light pieces',
      recommend: 'Coat or heavy outerwear · Dark rich tones · Formal or streetwear',
    );
  }

  // ── Bottom nav ──────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    const items = [
      {'icon': Icons.home_outlined,     'label': 'Home'},
      {'icon': Icons.checkroom_outlined, 'label': 'Closet'},
      {'icon': null,                     'label': ''},
      {'icon': Icons.style_outlined,    'label': 'Outfits'},
      {'icon': Icons.person_outline,    'label': 'Profile'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(top: BorderSide(color: Color(0xFFE2E0DC), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              if (i == 2) {
                return GestureDetector(
                  onTap: _showUploadSheet,
                  child: Container(
                    width: 44,
                    height: 44,
                    color: _ink,
                    child: const Icon(Icons.add,
                        size: 22, color: Color(0xFFC8C4BE)),
                  ),
                );
              }
              final icon     = items[i]['icon'] as IconData;
              final label    = items[i]['label'] as String;
              final tabIndex = i;
              final active   = _selectedIndex == tabIndex;
              return GestureDetector(
                onTap: () => _onTabTap(tabIndex),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 22,
                        color: active ? _ink : _muted),
                    const SizedBox(height: 4),
                    Text(label.toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            color: active ? _ink : _muted)),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  const _IconBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD8D6D2), width: 0.5)),
      child: Icon(icon, size: 17, color: const Color(0xFF4A4844)),
    );
  }
}

// ── Weather advice data class ─────────────────────────────────────────

class _WeatherAdvice {
  final String tag;
  final String headline;
  final String body;
  final String avoid;
  final String recommend;

  const _WeatherAdvice({
    required this.tag,
    required this.headline,
    required this.body,
    required this.avoid,
    required this.recommend,
  });
}

// ── Weather suggestion card ───────────────────────────────────────────

class _WeatherSuggestionCard extends StatefulWidget {
  final double temperature;
  final String condition;
  final _WeatherAdvice advice;

  const _WeatherSuggestionCard({
    required this.temperature,
    required this.condition,
    required this.advice,
  });

  @override
  State<_WeatherSuggestionCard> createState() =>
      _WeatherSuggestionCardState();
}

class _WeatherSuggestionCardState extends State<_WeatherSuggestionCard> {
  bool _expanded = false;

  static const Color _bg       = Color(0xFFF5F4F2);
  static const Color _ink      = Color(0xFF1A1814);
  static const Color _sand     = Color(0xFFC8C4BE);
  static const Color _muted    = Color(0xFF8A8784);
  static const Color _cardBg   = Color(0xFFFFFFFF);
  static const Color _border   = Color(0xFFE2E0DC);
  static const Color _darkMuted = Color(0xFF6B6862);
  static const Color _darkBorder = Color(0xFF2E2C28);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFD8D6D2), width: 0.5),
          ),
        ),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 260),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: _buildCollapsed(),
          secondChild: _buildExpanded(),
        ),
      ),
    );
  }

  // ── Collapsed view — teaser only ──────────────────────────────────

  Widget _buildCollapsed() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          // Tag pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: _ink,
            child: Text(widget.advice.tag,
                style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.4,
                    color: _sand)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(widget.advice.headline,
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: _ink)),
          ),
          Icon(Icons.keyboard_arrow_down,
              size: 16, color: _muted),
        ],
      ),
    );
  }

  // ── Expanded view — full advice ───────────────────────────────────

  Widget _buildExpanded() {
    return Container(
      color: _ink,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    border: Border.all(color: _darkBorder, width: 0.5)),
                child: Text(widget.advice.tag,
                    style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.4,
                        color: _darkMuted)),
              ),
              GestureDetector(
                onTap: () => setState(() => _expanded = false),
                child: Icon(Icons.keyboard_arrow_up,
                    size: 16, color: _darkMuted),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Headline
          Text(widget.advice.headline,
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: _sand,
                  height: 1.0)),

          const SizedBox(height: 10),

          // Body advice
          Text(widget.advice.body,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: _darkMuted,
                  height: 1.6)),

          const SizedBox(height: 16),

          // Divider
          Container(height: 0.5, color: _darkBorder),
          const SizedBox(height: 14),

          // Avoid row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                padding: const EdgeInsets.only(top: 1),
                child: Text('AVOID',
                    style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.4,
                        color: const Color(0xFF6B6862))),
              ),
              Expanded(
                child: Text(widget.advice.avoid,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF8A8784),
                        height: 1.5)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Recommend row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                padding: const EdgeInsets.only(top: 1),
                child: Text('WEAR',
                    style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.4,
                        color: _sand)),
              ),
              Expanded(
                child: Text(widget.advice.recommend,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        color: _sand,
                        height: 1.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
