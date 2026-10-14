import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/leaderboard_provider.dart';
import 'package:sportx_app/theme/colors.dart';

/// v3 AT.1 home strip — top-5 slice, horizontal scroll, View all → /leaderboard.
class LeaderboardStrip extends ConsumerWidget {
  const LeaderboardStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strip = ref.watch(leaderboardStripProvider);
    return strip.when(
      loading: () => const SizedBox(height: 90),
      error: (_, _) => const SizedBox.shrink(),
      data: (rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        return Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Leaderboard', style: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final e = rows[i];
                return Container(
                  width: 150,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('#${e.rank} ${e.displayName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                    Text('${e.points} pts', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                  ]),
                );
              },
            ),
          ),
        ]);
      },
    );
  }
}
