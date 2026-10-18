import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/shared/providers/providers.dart';
import 'package:sportx_app/shared/presentation/widgets/home_kit.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

/// S.12 Community — Network / Groups / Events tabs per design: search entry,
/// People/Academies chips, suggested person rows + acadCard (Network tab),
/// group list cards (Groups), event list rows (Events).
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
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
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _CommunityTabs(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityTabs extends StatefulWidget {
  const _CommunityTabs();

  @override
  State<_CommunityTabs> createState() => _CommunityTabsState();
}

class _CommunityTabsState extends State<_CommunityTabs> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        KitTabBar(
          labels: const ['Network', 'Groups', 'Events'],
          activeIndex: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        if (_tab == 0) ...[
          SportXSearchBar(hint: 'Search people, groups', onTap: () => context.push('/universal-search')),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                SportXChip(label: 'Athletes', selected: true, onTap: () => context.push('/athlete-directory')),
                const SizedBox(width: 7),
                SportXChip(label: 'Coaches', onTap: () => context.push('/coaches')),
                const SizedBox(width: 7),
                SportXChip(label: 'Academies', onTap: () => context.push('/academies')),
                const SizedBox(width: 7),
                SportXChip(label: 'My network', icon: LucideIcons.users, onTap: () => context.push('/network')),
                const SizedBox(width: 7),
              ],
            ),
          ),
          const _SuggestedSection(),
        ] else if (_tab == 1)
          const _GroupsSection()
        else
          const _EventsSection(),
      ],
    );
  }
}

// ─── Network tab ──────────────────────────────────────────────────────────────

class _SuggestedSection extends ConsumerWidget {
  const _SuggestedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athletes = ref.watch(athletesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeadV3(
          title: 'Suggested for you',
          actionText: 'My network',
          onActionTap: () => context.push('/network'),
        ),
        athletes.when(
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(18),
            child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          )),
          error: (_, _) => emptyHint('Could not load suggestions right now.'),
          data: (state) {
            if (state.isEmpty) return emptyHint('More athletes will appear here as they join SportX.');
            return Column(
              children: [
                for (final a in state.take(4))
                  PersonRowCard(
                    name: (a['full_name'] ?? a['name'] ?? 'Athlete').toString(),
                    role: a['sport'] is Map && a['sport']['name'] != null
                        ? a['sport']['name'].toString()
                        : 'Athlete',
                    photoUrl: _photo((a['profile_photo_url'] ?? '').toString()),
                    ctaLabel: 'Follow',
                    onTap: () => context.push('/view-profile', extra: {'type': 'athlete', 'id': a['id']?.toString() ?? ''}),
                  ),
              ],
            );
          },
        ),
        Builder(
          builder: (context) {
            final acadState = ref.watch(academiesProvider);
            if (acadState.isLoading && acadState.items.isEmpty) return const SizedBox.shrink();
            if (acadState.items.isEmpty) return const SizedBox.shrink();
            final a = acadState.items.first;
            return _AcademyWideCard(
              name: a.name,
              location: a.city?.name ?? '',
              photoUrl: MediaUtils.resolveNullable(a.logoUrl),
              onTap: () => context.push('/academy-detail/${a.id}'),
            );
          },
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _AcademyWideCard extends StatelessWidget {
  final String name;
  final String location;
  final String? photoUrl;
  final VoidCallback onTap;
  const _AcademyWideCard({required this.name, required this.location, this.photoUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
          boxShadow: SportXShadows.e1,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            kitNetImage(url: photoUrl ?? '', width: 104, height: 86, radius: 10),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3, right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sora(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 10, color: AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sports Academy', style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary)),
                        Text('View ›',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryDarker)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Groups tab (S.13) ──────────────────────────────────────────────────────

class _GroupsSection extends StatelessWidget {
  const _GroupsSection();

  static const _groups = [
    (name: 'Cricket Coaches India', detail: 'Coaching community · Ask, share drills'),
    (name: 'Youth Training & Development', detail: 'Trainers and academies · Programs'),
    (name: 'Trial Alerts Gujarat', detail: 'Scouts and athletes · Trials near you'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeadV3(
          title: 'Popular groups',
          actionText: 'My network',
          onActionTap: () => context.push('/network'),
        ),
        for (final g in _groups) ...[
          Container(
            padding: const EdgeInsets.all(13),
            margin: const EdgeInsets.only(bottom: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: SportXShadows.e1,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.yellowTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.usersRound, size: 20, color: AppColors.primaryDarker),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 3),
                      Text(g.detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SportXChip(
                  label: 'Join',
                  icon: LucideIcons.plus,
                  onTap: () => context.push('/network'),
                ),
              ],
            ),
          ),
        ],
        emptyHint('Group spaces are opening up gradually — join your network to stay in the loop.'),
        const SizedBox(height: 100),
      ],
    );
  }
}

// ─── Events tab ─────────────────────────────────────────────────────────────

class _EventsSection extends ConsumerWidget {
  const _EventsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trials = ref.watch(trialsProvider);
    final tournaments = ref.watch(tournamentsProvider);
    final hasData = trials.items.isNotEmpty || tournaments.items.isNotEmpty;
    if (!hasData) {
      return Column(children: [emptyHint('No upcoming events yet — trials and tournaments will show here.'), const SizedBox(height: 100)]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeadV3(
          title: 'Upcoming events',
          actionText: 'See all',
          onActionTap: () => context.push('/tournaments'),
        ),
        for (final t in tournaments.items.take(4))
          _EventWideRow(
            title: t.title,
            date: t.startDate,
            location: t.venue ?? '',
            typeLabel: 'Tournament',
            onTap: () => context.push('/tournament-detail/${t.id}'),
          ),
        for (final t in trials.items.take(4))
          _EventWideRow(
            title: t.title,
            date: t.trialDate,
            location: t.venue ?? '',
            typeLabel: 'Trial',
            onTap: () => context.push('/trial-detail/${t.id}'),
          ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _EventWideRow extends StatelessWidget {
  final String title;
  final DateTime? date;
  final String location;
  final String typeLabel;
  final VoidCallback onTap;
  const _EventWideRow({required this.title, required this.date, required this.location, required this.typeLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = date;
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
          boxShadow: SportXShadows.e1,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.yellowTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(d != null ? months[d.month - 1] : 'TBA',
                      style: GoogleFonts.sora(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.primaryDarker)),
                  Text(d != null ? '${d.day}' : '–',
                      style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 10, color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TypeChip(label: typeLabel),
          ],
        ),
      ),
    );
  }
}

String _photo(String raw) => raw.isNotEmpty ? MediaUtils.resolveUrl(raw) : '';
