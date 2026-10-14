import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/leaderboard_provider.dart';
import 'package:sportx_app/theme/colors.dart';

/// v3 S.6 Leaderboard — podium (top 3) + ranks 4-10, sport filter chips.
/// v3 tokens: yellow gradient rank badges, white cards on surface, Sora titles.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider({}));
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        elevation: 0,
        title: Text('Leaderboard',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load leaderboard')),
        data: (lb) {
          if (lb.error != null) return Center(child: Text(lb.error!));
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Text('Top 3 this season',
                  style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (lb.podium.length > 1) Expanded(child: _podiumCard(lb.podium[1], 2)),
                  if (lb.podium.isNotEmpty) Expanded(child: _podiumCard(lb.podium[0], 1, tall: true)),
                  if (lb.podium.length > 2) Expanded(child: _podiumCard(lb.podium[2], 3)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Ranks 4–10',
                  style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 10),
              ...lb.ranks.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [
                              Color(0xFFFFD54A),
                              Color(0xFFFFC107),
                              Color(0xFFF5B400)
                            ])),
                        child: Text('${e.rank}',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.ink)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.displayName,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('${e.sportName ?? 'Athlete'} • ${e.points} pts',
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                        ]),
                      ),
                      if (e.isMinor)
                        const Icon(LucideIcons.shield, size: 16, color: AppColors.textTertiary),
                    ]),
                  )),
              if (lb.podium.isEmpty && lb.ranks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(14)),
                  child: Text('No ranks yet. Verified achievements move you up.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _podiumCard(LeaderboardEntry e, int place, {bool tall = false}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(vertical: tall ? 18 : 12, horizontal: 8),
        decoration: BoxDecoration(
            color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Color(0xFFFFD54A), Color(0xFFFFC107), Color(0xFFF5B400)])),
            child: Text('$place', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 8),
          Text(e.displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
          Text('${e.points} pts', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
        ]),
      );
}
