import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/leaderboard_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/home_kit.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/shared/providers/providers.dart';
import 'package:sportx_app/theme/colors.dart';

/// SC.2 Scout dashboard — greeting ("Find the next big talent"), Top Talents
/// podium, quick chips (Discover / Trials / Top Perf. / Shortlist), upcoming
/// trials list and feed — per design.
class TalentScoutDashboardScreen extends ConsumerWidget {
  const TalentScoutDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.name.split(' ').first ?? 'Scout';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.yellowDeep,
        onRefresh: () async {
          ref.invalidate(leaderboardProvider);
          await ref.read(trialsProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.96),
              pinned: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: 68,
              titleSpacing: 16,
              title: Row(
                children: const [
                  Expanded(child: SportXWordmark()),
                  HomeHeaderActions(),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GreetCardV3(
                    greeting: greetingFor(DateTime.now()),
                    name: 'Hi, $name! Find the next big talent',
                    subtitle: 'Shortlist athletes to build scouting reports',
                    progress: 0.65,
                    ctaLabel: 'Discover',
                    onCta: () => context.push('/scout-discovery'),
                  ),
                  const _PodiumSection(),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        SportXChip(label: 'Discover', selected: true, onTap: () => context.push('/scout-discovery')),
                        const SizedBox(width: 7),
                        SportXChip(label: 'Trials', onTap: () => context.push('/trials')),
                        const SizedBox(width: 7),
                        SportXChip(label: 'Top Perf.', onTap: () => context.push('/leaderboard')),
                        const SizedBox(width: 7),
                        SportXChip(label: 'Shortlist', onTap: () => context.push('/scout-shortlist')),
                        const SizedBox(width: 7),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const _UpcomingTrials(),
                  const SizedBox(height: 14),
                  const V3FeedPreview(),
                  const SizedBox(height: 96),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Top Talents podium (SC.2 .podium with .p.first middle crown)
// ────────────────────────────────────────────────────────────────────────────

class _PodiumSection extends ConsumerWidget {
  const _PodiumSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strip = ref.watch(leaderboardStripProvider);
    final entries = strip.valueOrNull ?? const <LeaderboardEntry>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeadV3(
            title: 'Top Talents (This Week)',
            actionText: 'See all',
            onActionTap: () => context.push('/leaderboard')),
        if (strip.isLoading && entries.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(14),
            child: ThemeCircularLoader(),
          ))
        else if (entries.isEmpty)
          emptyHint('Top performers publish here once leaderboards update.')
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: SportXShadows.e1,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _picks(entries),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  List<Widget> _picks(List<LeaderboardEntry> entries) {
    // Design order: #2 left, #1 middle (raised), #3 right.
    final one = entries.length > 0 ? entries[0] : null;
    final two = entries.length > 1 ? entries[1] : null;
    final three = entries.length > 2 ? entries[2] : null;
    return [
      _PodiumTile(entry: two, rank: 2),
      const SizedBox(width: 12),
      _PodiumTile(entry: one, rank: 1, first: true),
      const SizedBox(width: 12),
      _PodiumTile(entry: three, rank: 3),
    ];
  }
}

class _PodiumTile extends StatelessWidget {
  final LeaderboardEntry? entry;
  final int rank;
  final bool first;
  const _PodiumTile({required this.entry, required this.rank, this.first = false});

  @override
  Widget build(BuildContext context) {
    final size = first ? 49.0 : 40.0;
    final name = entry?.displayName ?? 'TBA';
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.yellow, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(name.split(RegExp(r'\s+')).isNotEmpty && name.trim().isNotEmpty
              ? name.trim().split(RegExp(r'\s+'))[0][0].toUpperCase()
              : 'A',
              style: GoogleFonts.sora(fontSize: first ? 17 : 14, fontWeight: FontWeight.w800, color: AppColors.primaryDarker)),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 66,
          child: Column(
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: first ? 10.5 : 9.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
              Text('#$rank · ${entry?.points ?? 0} pts',
                  style: GoogleFonts.inter(fontSize: 8.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class ThemeCircularLoader extends StatelessWidget {
  const ThemeCircularLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.yellowDeep),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Upcoming trials card list (SC.2 trailing module)
// ────────────────────────────────────────────────────────────────────────────

class _UpcomingTrials extends ConsumerWidget {
  const _UpcomingTrials();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trials = ref.watch(trialsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeadV3(title: 'Upcoming Trials & Events',
            actionText: 'See all',
            onActionTap: () => context.push('/trials')),
        if (trials.isLoading && trials.items.isEmpty)
          emptyHint('Loading trials…')
        else if (trials.items.isEmpty)
          emptyHint('No upcoming trials right now — check back soon.')
        else
          ...trials.items.take(3).map((t) => GestureDetector(
                onTap: () => context.push('/trial-detail/${t.id}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: SportXShadows.e1,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                            const SizedBox(height: 3),
                            Text(t.venue ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text('Registrations Open',
                            style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                      ),
                      Text('View ›',
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryDarker)),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
