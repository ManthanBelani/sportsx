import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/opportunity/presentation/providers/opportunity_provider.dart';
import 'package:sportx_app/shared/providers/providers.dart';
import 'package:sportx_app/shared/providers/role_config_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/home_kit.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// S.2 Explore — browse rails per design: search entry, category chips, then
/// Popular Athletes / Coaches / Academies / Events rails + Opportunities.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(roleConfigProvider);

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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SportXSearchBar(hint: 'Search athletes, coaches, academies…',
                    onTap: () => context.push('/universal-search')),
                const SizedBox(height: 10),
                // Role-specific shortcuts — the same shell, role-relevant
                // destinations.
                if (config.discoverLinks.isNotEmpty) ...[
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final link in config.discoverLinks) ...[
                          SportXChip(
                            label: link.label,
                            icon: link.icon,
                            onTap: () => context.push(link.route),
                          ),
                          const SizedBox(width: 7),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      const SportXChip(label: 'All', selected: true, icon: LucideIcons.compass),
                      const SizedBox(width: 7),
                      for (final c in const [
                        (label: 'Athletes', icon: LucideIcons.user, route: '/athlete-directory'),
                        (label: 'Coaches', icon: LucideIcons.user, route: '/coaches'),
                        (label: 'Academies', icon: LucideIcons.building2, route: '/academies'),
                        (label: 'Events', icon: LucideIcons.calendar, route: '/tournaments'),
                      ]) ...[
                        SportXChip(label: c.label, icon: c.icon, onTap: () => context.push(c.route)),
                        const SizedBox(width: 7),
                      ],
                    ],
                  ),
                ),
                _Section(title: 'Popular Athletes', action: 'See all', onAction: () => context.push('/athlete-directory'), child: const _AthletesRail()),
                _Section(title: 'Coaches', action: 'See all', onAction: () => context.push('/coaches'), child: const _CoachesRail()),
                _Section(title: 'Academies', action: 'See all', onAction: () => context.push('/academies'), child: const _AcademiesRail()),
                _Section(title: 'Events', action: 'See all', onAction: () => context.push('/tournaments'), child: const _EventsRail()),
                _Section(title: 'Opportunities', action: 'See all', onAction: () => context.push('/opportunities'), child: const _OppsList()),
                const SizedBox(height: 90),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;
  final Widget child;
  const _Section({required this.title, required this.action, required this.onAction, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeadV3(title: title, actionText: action, onActionTap: onAction),
        Padding(
          padding: const EdgeInsets.only(left: 0, bottom: 6),
          child: child,
        ),
      ],
    );
  }
}

class _AthletesRail extends ConsumerWidget {
  const _AthletesRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athletes = ref.watch(athletesProvider);
    return athletes.when(
      loading: () => const _RailSkeleton(),
      error: (_, _) => emptyHint('Could not load athletes right now.'),
      data: (rows) {
        if (rows.isEmpty) return emptyHint('No athletes yet.');
        return _rail(
          rows.take(8).map((a) {
            final name = (a['full_name'] ?? a['name'] ?? 'Athlete').toString();
            String role = 'Athlete';
            if (a['sport'] is Map && a['sport']['name'] != null) role = a['sport']['name'].toString();
            final photo = (a['profile_photo_url'] ?? '').toString();
            final id = a['id']?.toString() ?? '';
            return RailPersonCard(
              name: name,
              role: role,
              photoUrl: photo.isNotEmpty ? MediaUtils.resolveUrl(photo) : null,
              ctaLabel: 'View',
              onTap: () => context.push('/view-profile', extra: {'type': 'athlete', 'id': id}),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CoachesRail extends ConsumerWidget {
  const _CoachesRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coachesProvider);
    if (state.isLoading && state.items.isEmpty) return const _RailSkeleton();
    if (state.items.isEmpty) return emptyHint('No coaches yet.');
    return _rail(
      state.items.take(8).map((c) {
        return RailPersonCard(
          name: c.fullName,
          role: c.specialization ?? 'Coach',
          photoUrl: MediaUtils.resolveNullable(c.profilePhotoUrl ?? ''),
          ctaLabel: 'View',
          onTap: () => context.push('/coach-detail/${c.id}'),
        );
      }).toList(),
    );
  }
}

class _AcademiesRail extends ConsumerWidget {
  const _AcademiesRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(academiesProvider);
    if (state.isLoading && state.items.isEmpty) return const _RailSkeleton();
    if (state.items.isEmpty) return emptyHint('No academies yet.');
    return _rail(
      state.items.take(8).map((a) {
        return RailAcademyCard(
          name: a.name,
          location: a.city?.name ?? '',
          photoUrl: MediaUtils.resolveNullable(a.logoUrl),
          onTap: () => context.push('/academy-detail/${a.id}'),
        );
      }).toList(),
    );
  }
}

class _EventsRail extends ConsumerWidget {
  const _EventsRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trials = ref.watch(trialsProvider);
    final tournaments = ref.watch(tournamentsProvider);
    final cards = <RailEventCard>[
      ...trials.items.take(4).map((t) => RailEventCard(
            title: t.title,
            location: t.venue ?? '',
            date: t.trialDate,
            typeLabel: 'Trial',
            onTap: () => context.push('/trial-detail/${t.id}'),
          )),
      ...tournaments.items.take(4).map((t) => RailEventCard(
            title: t.title,
            location: t.venue ?? '',
            date: t.startDate,
            typeLabel: 'Tournament',
            onTap: () => context.push('/tournament-detail/${t.id}'),
          )),
    ];
    if (cards.isEmpty) return emptyHint('No upcoming events yet.');
    return _rail(cards);
  }
}

class _OppsList extends ConsumerWidget {
  const _OppsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunities = ref.watch(opportunitiesProvider);
    final tiles = <Widget>[
      ...opportunities.items.take(4).map((o) => _OppRow(
            title: o.title,
            org: o.deadline == null
                ? 'Open now'
                : 'By ${o.deadline!.toLocal().toString().substring(0, 10)}',
            chip: o.type == 'sponsorship' ? 'Sponsorship' : 'Scholarship',
            onTap: () => context.push('/opportunity-detail/${o.id}'),
          )),
    ];
    if (tiles.isEmpty) return emptyHint('No open opportunities yet.');
    return Column(children: tiles);
  }
}

class _OppRow extends StatelessWidget {
  final String title;
  final String org;
  final String chip;
  final VoidCallback onTap;
  const _OppRow({required this.title, required this.org, required this.chip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            Icon(
                chip == 'Scholarship' ? LucideIcons.graduationCap : LucideIcons.briefcase,
                size: 20,
                color: AppColors.primaryDarker),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(org,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary)),
              ]),
            ),
            TypeChip(label: chip),
          ],
        ),
      ),
    );
  }
}

Widget _rail(List<Widget> kids) {
  return SizedBox(
    height: 186,
    child: ListView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      children: kids,
    ),
  );
}

class _RailSkeleton extends StatelessWidget {
  const _RailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 184,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, _) => Container(
          width: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}
