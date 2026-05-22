import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';

class StylePreferencesScreen extends ConsumerStatefulWidget {
  const StylePreferencesScreen({super.key});

  @override
  ConsumerState<StylePreferencesScreen> createState() =>
      _StylePreferencesScreenState();
}

class _StylePreferencesScreenState extends ConsumerState<StylePreferencesScreen> {
  final List<String> selectedStyles = [];
  final List<String> selectedColors = [];
  final List<String> selectedOccasions = [];
  String? selectedSize;
  bool isSaving = false;

  static const Color _bg = Color(0xFF1A1814);
  static const Color _sand = Color(0xFFC8C4BE);
  static const Color _sandDim = Color(0xFF6B6862);
  static const Color _divider = Color(0xFF2A2825);
  static const Color _timeLabel = Color(0xFF4A4844);
  static const Color _watermark = Color(0xFF252320);

  static const List<String> _styleOptions = [
    'Casual', 'Formal', 'Streetwear', 'Vintage',
    'Minimalist', 'Boho', 'Y2K', 'Old Money',
  ];
  static const List<String> _colorOptions = [
    'Monochrome', 'Neutrals', 'Pastels',
    'Earth Tones', 'Bold', 'Dark & Moody',
  ];
  static const List<String> _occasionOptions = [
    'Everyday', 'Work', 'Night Out',
    'Travel', 'Gym', 'Events',
  ];
  static const List<String> _sizeOptions = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL',
  ];

void _toggle(List<String> list, String value) {
    setState(() {
      list.contains(value) ? list.remove(value) : list.add(value);
    });
  }

Future<void> _finishSetup() async {
    // Debug log
    debugPrint('Finish setup clicked');

    // Validation: require at least clothing size and one preference
    if (selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select your clothing size',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
          backgroundColor: const Color(0xFF2E2C28),
          behavior: SnackBarBehavior.floating,
        ),
      );
      debugPrint('Validation failed: no size selected');
      return;
    }

    if (selectedStyles.isEmpty && selectedColors.isEmpty && selectedOccasions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one style, color, or occasion preference',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
          backgroundColor: const Color(0xFF2E2C28),
          behavior: SnackBarBehavior.floating,
        ),
      );
      debugPrint('Validation failed: no preferences selected');
      return;
    }

    setState(() => isSaving = true);
    debugPrint('isSaving set to true');

    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        throw Exception('No signed-in user found');
      }

      await ref.read(authServiceProvider).updateUserProfile(
        uid: user.uid,
        data: {
          'styles': selectedStyles,
          'colors': selectedColors,
          'occasions': selectedOccasions,
          'clothingSize': selectedSize,
        },
      );
      await ref.read(authProvider.notifier).completeOnboarding();

      debugPrint('About to navigate to home page');
      if (mounted) {
        context.go('/home');
        debugPrint('Navigated home');
      }
    } catch (e) {
      debugPrint('Failed to finish setup: $e');
      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not finish setup. Please try again.',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            ),
            backgroundColor: const Color(0xFF2E2C28),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            bottom: -20,
            right: -10,
            child: Text(
              '04',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 52),
Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          _StepDot(active: true),
                          SizedBox(width: 5),
                          _StepDot(active: true),
                          SizedBox(width: 5),
                          _StepDot(active: true),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'STEP 3 OF 3',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.2,
                      color: _sandDim,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Define your\nstyle.',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                      color: _sand,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose what you love to wear.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: _sandDim,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel(label: 'AESTHETIC'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _styleOptions.map((s) {
                      return GestureDetector(
                        onTap: () => _toggle(selectedStyles, s),
                        child: _Chip(
                          label: s,
                          selected: selectedStyles.contains(s),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'COLOUR PALETTE'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _colorOptions.map((c) {
                      return GestureDetector(
                        onTap: () => _toggle(selectedColors, c),
                        child: _Chip(
                          label: c,
                          selected: selectedColors.contains(c),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'OCCASION'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _occasionOptions.map((o) {
                      return GestureDetector(
                        onTap: () => _toggle(selectedOccasions, o),
                        child: _Chip(
                          label: o,
                          selected: selectedOccasions.contains(o),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'CLOTHING SIZE'),
                  const SizedBox(height: 10),
                  Row(
                    children: _sizeOptions.map((s) {
                      final isSelected = selectedSize == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => selectedSize = s),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF252320)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? _sand
                                    : const Color(0xFF2E2C28),
                                width: 0.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                s,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.8,
                                  color: isSelected ? _sand : _sandDim,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    width: double.infinity,
                    height: 0.5,
                    color: _divider,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STEP 3\nOF 3',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.4,
                          color: _timeLabel,
                          height: 1.5,
                        ),
                      ),
MaterialButton(
                        onPressed: isSaving ? null : _finishSetup,
                        color: _sand,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        child: Text(
                          'FINISH SETUP',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2.2,
                            color: _bg,
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.8,
        color: const Color(0xFF6B6862),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  const _Chip({required this.label, required this.selected});

  static const Color _border = Color(0xFF2E2C28);
  static const Color _borderSel = Color(0xFFC8C4BE);
  static const Color _bgSel = Color(0xFF252320);
  static const Color _textNormal = Color(0xFF6B6862);
  static const Color _textSel = Color(0xFFC8C4BE);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? _bgSel : Colors.transparent,
        border: Border.all(
          color: selected ? _borderSel : _border,
          width: 0.5,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.2,
          color: selected ? _textSel : _textNormal,
        ),
      ),
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
