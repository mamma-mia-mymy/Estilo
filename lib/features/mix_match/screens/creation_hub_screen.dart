import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class CreationHubScreen extends StatelessWidget {
  const CreationHubScreen({super.key});

  static const Color _bg = Color(0xFFF5F4F2);
  static const Color _ink = Color(0xFF1A1814);
  static const Color _muted = Color(0xFF8A8784);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              _buildCards(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CREATE',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.0,
                      color: _muted)),
              const SizedBox(height: 6),
              Text("What's next?",
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: _ink)),
            ],
          ),
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                border:
                    Border.all(color: const Color(0xFFE2E0DC), width: 0.5),
              ),
              child: const Icon(Icons.close, size: 18, color: _ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _CreationCard(
            icon: Icons.camera_alt_outlined,
            title: 'UPLOAD PHOTO',
            subtitle: 'Add clothing to your wardrobe',
            cta: 'Get started',
            onTap: () {
              context.push('/creation-hub/upload');
            },
          ),
          const SizedBox(height: 16),
          _CreationCard(
            icon: Icons.style_outlined,
            title: 'MIX & MATCH OUTFIT',
            subtitle: 'Create and score outfit combinations',
            cta: 'Start mixing',
            onTap: () {
              context.push('/mix-match');
            },
          ),
        ],
      ),
    );
  }
}

class _CreationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;

  const _CreationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
  });

  static const Color _ink = Color(0xFF1A1814);
  static const Color _muted = Color(0xFF8A8784);
  static const Color _border = Color(0xFFE2E0DC);
  static const Color _cardBg = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F6),
                border: Border.all(color: _border, width: 0.5),
              ),
              child: Icon(icon, size: 24, color: _muted),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: _ink),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: _muted,
                  height: 1.5),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  cta,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                      color: _ink),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 14, color: _ink),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
