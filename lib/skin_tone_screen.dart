import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/profile_provider.dart';
import 'style_preferences_screen.dart';

class SkinToneScreen extends ConsumerStatefulWidget {
  const SkinToneScreen({super.key});

  @override
  ConsumerState<SkinToneScreen> createState() => _SkinToneScreenState();
}

class _SkinToneScreenState extends ConsumerState<SkinToneScreen> {
  int? selectedToneIndex;
  bool isSaving = false;

  static const Color _bg = Color(0xFF1A1814);
  static const Color _sand = Color(0xFFC8C4BE);
  static const Color _sandDim = Color(0xFF6B6862);
  static const Color _divider = Color(0xFF2A2825);
  static const Color _timeLabel = Color(0xFF4A4844);
  static const Color _watermark = Color(0xFF252320);

  static const List<Map<String, dynamic>> _skinTones = [
    {'label': 'Fair',   'color': Color(0xFFFFE0BD)},
    {'label': 'Light',  'color': Color(0xFFFFCBA4)},
    {'label': 'Medium', 'color': Color(0xFFCC9966)},
    {'label': 'Olive',  'color': Color(0xFFB97C6D)},
    {'label': 'Tan',    'color': Color(0xFF8D5524)},
    {'label': 'Deep',   'color': Color(0xFF5C4033)},
  ];

Future<void> _continue() async {
    if (selectedToneIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select your skin tone',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
          backgroundColor: const Color(0xFF2E2C28),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    final skinTone = _skinTones[selectedToneIndex!]['label'] as String;
    await ref.read(profileProvider.notifier).updateProfile(skinTone: skinTone);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => StylePreferencesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Watermark
          Positioned(
            bottom: -20,
            right: -10,
            child: Text(
              '03',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 200,
                fontWeight: FontWeight.w300,
                color: _watermark,
                height: 1,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 52),

// Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          _StepDot(active: false),
                          SizedBox(width: 5),
                          _StepDot(active: false),
                          SizedBox(width: 5),
                          _StepDot(active: true),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Eyebrow
                  Text(
                    'STEP 2 OF 3',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.2,
                      color: _sandDim,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Headline
                  Text(
                    'Your skin\ntone.',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                      color: _sand,
                      height: 1.05,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Helps us recommend colors and styles that complement you.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: _sandDim,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Tone grid
                  Expanded(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _skinTones.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, index) {
                        final tone = _skinTones[index];
                        final isSelected = selectedToneIndex == index;

                        return GestureDetector(
                          onTap: () =>
                              setState(() => selectedToneIndex = index),
                          child: _ToneCard(
                            label: tone['label'] as String,
                            color: tone['color'] as Color,
                            selected: isSelected,
                          ),
                        );
                      },
                    ),
                  ),

                  // Divider
                  Container(
                    width: double.infinity,
                    height: 0.5,
                    color: _divider,
                  ),

                  const SizedBox(height: 28),

                  // CTA row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STEP 2\nOF 3',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.4,
                          color: _timeLabel,
                          height: 1.5,
                        ),
                      ),
GestureDetector(
                        onTap: _continue,
                        child: Container(
                          color: _sand,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          child: Text(
                            'CONTINUE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2.2,
                              color: _bg,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToneCard extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;

  const _ToneCard({
    required this.label,
    required this.color,
    required this.selected,
  });

  static const Color _sand = Color(0xFFC8C4BE);
  static const Color _sandDim = Color(0xFF6B6862);
  static const Color _bg = Color(0xFF1A1814);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              // Swatch
              Container(
                width: double.infinity,
                height: double.infinity,
                color: color,
              ),

              // Selected border overlay
              if (selected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: _sand, width: 1),
                    ),
                  ),
                ),

              // Check mark
              if (selected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _bg,
                      border: Border.all(color: _sand, width: 0.5),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 11,
                      color: _sand,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Label
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.4,
            color: selected ? _sand : _sandDim,
          ),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  static const Color _active = Color(0xFFC8C4BE);
  static const Color _inactive = Color(0xFF3D3B37);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 32 : 20,
      height: 2,
      decoration: BoxDecoration(
        color: active ? _active : _inactive,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}