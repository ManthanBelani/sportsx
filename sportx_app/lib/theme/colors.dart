import 'package:flutter/material.dart';

class AppColors {
  // ── SportX v2 (matches sportsx-design-v2 :root) ──
  static const Color yellow = Color(0xFFFFC107);
  static const Color yellowDeep = Color(0xFFD9A400);
  static const Color yellowTint = Color(0xFFFFF6DA);
  static const Color yellowSoft = Color(0xFFFFF9E6);

  static const Color ink = Color(0xFF111111);
  static const Color dark = Color(0xFF2B2B2B);

  // Legacy names kept so 122 call sites keep working — values remapped to v2.
  static const Color primary = Color(0xFFD9A400); // v2 yellow-deep (was blue)
  static const Color cta = Color(0xFFFFC107); // v2 yellow CTA (was orange)

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF4F5F7); // v2 --bg
  static const Color cardBackground = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  static const Color border = Color(0xFFE8EAED); // v2 --border
  static const Color borderSoft = Color(0xFFEFF1F4);

  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warnText = Color(0xFFB45309);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFE3EFFF);

  static const Color primaryLight = Color(0xFFFFD54A);
  static const Color primaryDark = Color(0xFFD9A400);
  static const Color primaryDarker = Color(0xFF8A6D00);

  static const Color ctaDark = Color(0xFFF5B400);
  static const Color ctaLight = Color(0xFFFFF6DA);

  static const Color sportBadgeBg = Color(0xFFE3EFFF);
  static const Color verifiedBadge = Color(0xFF22C55E);
  static const Color mandatoryIndicator = Color(0xFFEF4444);

  // Role accents (v2 showcase)
  static const Color coach = Color(0xFF8A6AEA);
  static const Color academy = Color(0xFF03B94C);
  static const Color organizer = Color(0xFFFB802E);
  static const Color scout = Color(0xFF3B82F6);
  static const Color admin = Color(0xFFEF4444);
  static const Color shared = Color(0xFF06B6D4);
  static const Color pink = Color(0xFFF24C96);
  static const Color amberDeep = Color(0xFFFE9710);
}
