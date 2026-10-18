import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// S.7 Leaderboard Info — how ranking points are earned.
class LeaderboardInfoScreen extends StatelessWidget {
  const LeaderboardInfoScreen({super.key});

  static const _rules = [
    ('Profile completion', 'Up to 100 pts', 'Complete your profile, media and sports.'),
    ('Achievements', '50 pts each', 'Add medals, certificates and records.'),
    ('Posting activity', '10 pts each', 'Share posts, photos and updates.'),
    ('Events & trials', '25 pts each', 'Register for events and trials.'),
    ('Connections', '5 pts each', 'Follow and connect with others.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Leaderboard Info', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          SportXCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.yellowTint),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.trophy,
                      size: 24, color: AppColors.warnText),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Rankings are awarded from a weighted score of your profile '
                    'activity and achievements. Scores reset each season.',
                    style: GoogleFonts.inter(
                        fontSize: 13, height: 1.45, color: AppColors.dark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('How points work',
              style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 12),
          for (final r in _rules)
            SportXCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(LucideIcons.sparkles,
                      size: 18, color: AppColors.yellowDeep),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.$1,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                        const SizedBox(height: 2),
                        Text(r.$3,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text(r.$2,
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
