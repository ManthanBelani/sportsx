import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';

/// Store-mockup landing ("Let's defeat history").
///
/// Dark hero, yellow-highlight headline, 4-feature strip and a yellow CTA.
/// No photography: the mockup's athlete collage is replaced with a
/// yellow brush-stroke graphic treatment so the screen ships with zero
/// fake imagery.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              // Brand.
              Center(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.sora(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      color: Colors.white,
                    ),
                    children: const [
                      TextSpan(text: 'Sport'),
                      TextSpan(
                        text: 'X',
                        style: TextStyle(color: AppColors.yellow),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Text(
                  'I N D I A',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 6,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              // Headline with yellow highlight, like the mockup.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.sora(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: Colors.white,
                    ),
                    children: [
                      const TextSpan(text: "Let's\n"),
                      TextSpan(
                        text: 'defeat history',
                        style: const TextStyle(
                          backgroundColor: AppColors.yellow,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'A complete sports platform for every athlete in India',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              // Yellow brush-stroke band.
              CustomPaint(
                size: const Size(double.infinity, 90),
                painter: _StrokePainter(),
              ),
              const SizedBox(height: 6),
              // Feature strip.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _Feature(icon: LucideIcons.user, label: 'Athlete\nProfiles'),
                    _Feature(icon: LucideIcons.search, label: 'Opportunities'),
                    _Feature(icon: LucideIcons.users, label: 'Coaches &\nAcademies'),
                    _Feature(icon: LucideIcons.handshake, label: 'Sponsorships\n& Scholarships'),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              // CTA.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () => context.go('/role-selection'),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFD54A),
                          Color(0xFFFFC107),
                          Color(0xFFF5B400),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already a member? ',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.white70),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      'Log in',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.yellow,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Feature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.yellow, size: 26),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

/// Diagonal yellow brush strokes echoing the store artwork.
class _StrokePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.yellow;
    final h = size.height;
    final w = size.width;
    for (var i = 0; i < 3; i++) {
      final y = h * (0.2 + i * 0.3);
      final path = Path()
        ..moveTo(-20, y + 18)
        ..lineTo(w * 0.55, y - 14)
        ..lineTo(w * 0.62, y - 2)
        ..lineTo(w + 20, y - 22)
        ..lineTo(w + 20, y - 10)
        ..lineTo(w * 0.6, y + 12)
        ..lineTo(w * 0.53, y + 2)
        ..lineTo(-20, y + 30)
        ..close();
      canvas.drawPath(path, paint..color = AppColors.yellow.withValues(alpha: 0.85 - i * 0.2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
