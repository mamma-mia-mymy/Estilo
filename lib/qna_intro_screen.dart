import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'demographic_screen.dart';

class QnAIntroScreen extends StatelessWidget {
  const QnAIntroScreen({super.key});

  static const Color _bg = Color(0xFF1A1814);
  static const Color _sand = Color(0xFFC8C4BE);
  static const Color _sandDim = Color(0xFF6B6862);
  static const Color _sandFaint = Color(0xFF3A3834);
  static const Color _sandGhost = Color(0xFF252320);
  static const Color _dotInactive = Color(0xFF3D3B37);
  static const Color _pillBorder = Color(0xFF2E2C28);
  static const Color _pillText = Color(0xFF7A7874);
  static const Color _divider = Color(0xFF2A2825);
  static const Color _timeLabel = Color(0xFF4A4844);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Watermark number
          Positioned(
            bottom: -20,
            right: -10,
            child: Text(
              '01',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 200,
                fontWeight: FontWeight.w300,
                color: _sandGhost,
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
                      Row(
                        children: const [
                          _StepDot(active: true),
                          SizedBox(width: 5),
                          _StepDot(active: false),
                          SizedBox(width: 5),
                          _StepDot(active: false),
                        ],
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/home'),
                        child: Text(
                          'SKIP',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.4,
                            color: _sandDim,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Icon frame
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _pillBorder,
                        width: 0.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.checkroom_outlined,
                        size: 28,
                        color: _sand,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Eyebrow
                  Text(
                    'STYLE PROFILE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.2,
                      color: _sandDim,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Headline
                  Text(
                    'Build your\nwardrobe\nidentity.',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 46,
                      fontWeight: FontWeight.w400,
                      color: _sand,
                      height: 1.05,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Body
                  Text(
                    'A few quick questions help us understand how you dress — so Ternova can score outfits the way you think about style.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: _sandDim,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Pill row
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(label: 'Aesthetics'),
                      _Pill(label: 'Occasions'),
                      _Pill(label: 'Preferences'),
                    ],
                  ),

                  const Spacer(),

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
                        'Takes about\n2 minutes',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.4,
                          color: _timeLabel,
                          height: 1.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>  DemographicScreen(),
                            ),
                          );
                        },
                        child: Container(
                          color: _sand,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          child: Text(
                            'BEGIN SETUP',
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

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  static const Color _border = Color(0xFF2E2C28);
  static const Color _text = Color(0xFF7A7874);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: _border,
          width: 0.5,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.4,
          color: _text,
        ),
      ),
    );
  }
}