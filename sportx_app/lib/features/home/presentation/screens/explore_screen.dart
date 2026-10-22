import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/role_config.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/opportunity/presentation/providers/opportunity_provider.dart';
import 'package:sportx_app/features/organizer/presentation/widgets/organizer_kit.dart';
import 'package:sportx_app/shared/providers/providers.dart';
import 'package:sportx_app/shared/providers/role_config_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/home_kit.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// S.2 Explore — browse rails per design: search entry, category chips, then
/// Popular Athletes / Coaches / Academies / Events rails + Opportunities.
///
/// The organizer role renders the board's *organizer* explore (screen 2):
/// category tabs (Events / Venues / Athletes / Coaches / Academies) over a
/// sport chip row and a vertical event-card list.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(roleConfigProvider);

    if (config.role == SportXRole.organizer) return const _OrganizerExplore();

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
                SportXSearchBar(
                  hint: 'Search athletes, coaches, academies…',
                  onTap: () => context.push('/universal-search'),
                ),
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
                      const SportXChip(
                        label: 'All',
                        selected: true,
                        icon: LucideIcons.compass,
                      ),
                      const SizedBox(width: 7),
                      for (final c in const [
                        (
                          label: 'Athletes',
                          icon: LucideIcons.user,
                          route: '/athlete-directory',
                        ),
                        (
                          label: 'Coaches',
                          icon: LucideIcons.user,
                          route: '/coaches',
                        ),
                        (
                          label: 'Academies',
                          icon: LucideIcons.building2,
                          route: '/academies',
                        ),
                        (
                          label: 'Events',
                          icon: LucideIcons.calendar,
                          route: '/tournaments',
                        ),
                      ]) ...[
                        SportXChip(
                          label: c.label,
                          icon: c.icon,
                          onTap: () => context.push(c.route),
                        ),
                        const SizedBox(width: 7),
                      ],
                    ],
                  ),
                ),
                _Section(
                  title: 'Popular Athletes',
                  action: 'See all',
                  onAction: () => context.push('/athlete-directory'),
                  child: const _AthletesRail(),
                ),
                _Section(
                  title: 'Coaches',
                  action: 'See all',
                  onAction: () => context.push('/coaches'),
                  child: const _CoachesRail(),
                ),
                _Section(
                  title: 'Academies',
                  action: 'See all',
                  onAction: () => context.push('/academies'),
                  child: const _AcademiesRail(),
                ),
                _Section(
                  title: 'Events',
                  action: 'See all',
                  onAction: () => context.push('/tournaments'),
                  child: const _EventsRail(),
                ),
                _Section(
                  title: 'Opportunities',
                  action: 'See all',
                  onAction: () => context.push('/opportunities'),
                  child: const _OppsList(),
                ),
                const SizedBox(height: 90),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Design board · org-explore — search → category tabs → sport chips →
/// event cards with a "View" CTA.
class _OrganizerExplore extends ConsumerStatefulWidget {
  const _OrganizerExplore();

  @override
  ConsumerState<_OrganizerExplore> createState() => _OrganizerExploreState();
}

class _OrganizerExploreState extends ConsumerState<_OrganizerExplore> {
  static const _tabs = ['Events', 'Venues', 'Athletes', 'Coaches', 'Academies'];
  int _tab = 0;
  int? _sportId;
  final String _query = '';

  @override
  Widget build(BuildContext context) {
    final tournaments = ref.watch(tournamentsProvider);
    final trials = ref.watch(trialsProvider);
    final meta = ref.watch(metaProvider);

    final events = <Widget>[
      ...tournaments.items
          .where((t) => _sportId == null || t.sportId == _sportId)
          .where((t) => _matches(t.title))
          .map(
            (t) => _eventCard(
              title: t.title,
              start: t.startDate,
              end: t.endDate,
              location: [t.venue, t.city?.name]
                  .whereType<String>()
                  .where((s) => s.trim().isNotEmpty)
                  .join(', '),
              sportName: t.sport?.name,
              bannerUrl: t.bannerUrl,
              registered: t.confirmedRegistrationsCount,
              registrationsOpen: t.status == 'published',
              onTap: () => context.push('/tournament-detail/${t.id}'),
            ),
          ),
      ...trials.items
          .where((t) => _sportId == null || t.sportId == _sportId)
          .where((t) => _matches(t.title))
          .map(
            (t) => _eventCard(
              title: t.title,
              start: t.trialDate,
              location: [t.venue, t.city?.name]
                  .whereType<String>()
                  .where((s) => s.trim().isNotEmpty)
                  .join(', '),
              sportName: t.sport?.name,
              registered: t.filledSpots ?? 0,
              registrationsOpen: t.status == 'published',
              onTap: () => context.push('/trial-detail/${t.id}'),
            ),
          ),
    ];

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
                SportXSearchBar(
                  hint: 'Search events, venues, athletes, coaches, academies…',
                  onTap: () => context.push('/universal-search'),
                ),
                const SizedBox(height: 6),
                // Category tabs (Events · Venues · Athletes · Coaches · Academies)
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var i = 0; i < _tabs.length; i++) ...[
                        _tabLabel(
                          _tabs[i],
                          i == _tab,
                          () => setState(() => _tab = i),
                        ),
                        const SizedBox(width: 14),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                // Sport chips
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      SportXChip(
                        label: 'All Sports',
                        selected: _sportId == null,
                        onTap: () => setState(() => _sportId = null),
                      ),
                      const SizedBox(width: 7),
                      for (final s in meta.sports.where((s) => s.isActive))
                        Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: SportXChip(
                            label: s.name,
                            selected: _sportId == s.id,
                            onTap: () => setState(
                              () => _sportId = _sportId == s.id ? null : s.id,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                switch (_tab) {
                  0 => _eventsBody(
                    events,
                    tournaments.isLoading || trials.isLoading,
                  ),
                  1 => const _DirectoryBody(kind: _DirectoryKind.venues),
                  2 => const _DirectoryBody(kind: _DirectoryKind.athletes),
                  3 => const _DirectoryBody(kind: _DirectoryKind.coaches),
                  _ => const _DirectoryBody(kind: _DirectoryKind.academies),
                },
                const SizedBox(height: 90),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  bool _matches(String title) =>
      _query.isEmpty || title.toLowerCase().contains(_query);

  Widget _tabLabel(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.yellow : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? AppColors.ink : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _eventsBody(List<Widget> cards, bool loading) {
    if (loading && cards.isEmpty)
      return const GenericListSkeleton(itemCount: 4);
    if (cards.isEmpty) return emptyHint('No events match this filter yet.');
    return Column(
      children: [
        for (final c in cards)
          Padding(padding: const EdgeInsets.only(top: 10), child: c),
      ],
    );
  }

  Widget _eventCard({
    required String title,
    required DateTime? start,
    DateTime? end,
    required String location,
    String? sportName,
    String? bannerUrl,
    required int registered,
    required bool registrationsOpen,
    required VoidCallback onTap,
  }) {
    return OrgEventCard(
      title: title,
      start: start,
      end: end,
      location: location.isEmpty ? 'Location TBA' : location,
      sportName: sportName,
      bannerUrl: bannerUrl,
      registrationsOpen: registrationsOpen,
      registeredCount: registered,
      onTap: onTap,
      onView: onTap,
    );
  }
}

enum _DirectoryKind { venues, athletes, coaches, academies }

/// Venue / Athlete / Coach / Academy tabs of the organizer explore.
class _DirectoryBody extends ConsumerWidget {
  final _DirectoryKind kind;
  const _DirectoryBody({required this.kind});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (kind) {
      case _DirectoryKind.venues:
        final state = ref.watch(sportsVenuesProvider);
        if (state.isLoading && state.items.isEmpty)
          return const GenericListSkeleton(itemCount: 4);
        if (state.items.isEmpty) return emptyHint('No venues listed yet.');
        return Column(
          children: [
            for (final v in state.items.take(10))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: EntityRow(
                  title: v.name,
                  subtitle: v.city?.name ?? '',
                  avatarText: v.name.isNotEmpty ? v.name[0].toUpperCase() : 'V',
                  onTap: () => context.push('/sports-venue-detail/${v.id}'),
                ),
              ),
          ],
        );
      case _DirectoryKind.athletes:
        final athletes = ref.watch(athletesProvider);
        return athletes.when(
          loading: () => const GenericListSkeleton(itemCount: 4),
          error: (_, _) => emptyHint('Could not load athletes right now.'),
          data: (rows) {
            if (rows.isEmpty) return emptyHint('No athletes yet.');
            return Column(
              children: [
                for (final a in rows.take(10))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: EntityRow(
                      title: (a['full_name'] ?? a['name'] ?? 'Athlete')
                          .toString(),
                      subtitle: a['sport'] is Map
                          ? a['sport']['name'].toString()
                          : 'Athlete',
                      avatarText:
                          (a['full_name'] ?? a['name'] ?? 'A')
                              .toString()
                              .trim()
                              .isEmpty
                          ? 'A'
                          : (a['full_name'] ?? a['name'] ?? 'A')
                                .toString()
                                .trim()[0]
                                .toUpperCase(),
                      onTap: () => context.push(
                        '/view-profile',
                        extra: {
                          'type': 'athlete',
                          'id': a['id']?.toString() ?? '',
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      case _DirectoryKind.coaches:
        final state = ref.watch(coachesProvider);
        if (state.isLoading && state.items.isEmpty)
          return const GenericListSkeleton(itemCount: 4);
        if (state.items.isEmpty) return emptyHint('No coaches yet.');
        return Column(
          children: [
            for (final c in state.items.take(10))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: EntityRow(
                  title: c.fullName,
                  subtitle: c.specialization ?? 'Coach',
                  avatarText: c.fullName.trim().isEmpty
                      ? 'C'
                      : c.fullName.trim()[0].toUpperCase(),
                  onTap: () => context.push('/coach-detail/${c.id}'),
                ),
              ),
          ],
        );
      case _DirectoryKind.academies:
        final state = ref.watch(academiesProvider);
        if (state.isLoading && state.items.isEmpty)
          return const GenericListSkeleton(itemCount: 4);
        if (state.items.isEmpty) return emptyHint('No academies yet.');
        return Column(
          children: [
            for (final a in state.items.take(10))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: EntityRow(
                  title: a.name,
                  subtitle: a.city?.name ?? '',
                  avatarText: a.name.trim().isEmpty
                      ? 'A'
                      : a.name.trim()[0].toUpperCase(),
                  onTap: () => context.push('/academy-detail/${a.id}'),
                ),
              ),
          ],
        );
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;
  final Widget child;
  const _Section({
    required this.title,
    required this.action,
    required this.onAction,
    required this.child,
  });

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
            if (a['sport'] is Map && a['sport']['name'] != null)
              role = a['sport']['name'].toString();
            final photo = (a['profile_photo_url'] ?? '').toString();
            final id = a['id']?.toString() ?? '';
            return RailPersonCard(
              name: name,
              role: role,
              photoUrl: photo.isNotEmpty ? MediaUtils.resolveUrl(photo) : null,
              ctaLabel: 'View',
              onTap: () => context.push(
                '/view-profile',
                extra: {'type': 'athlete', 'id': id},
              ),
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
      ...trials.items
          .take(4)
          .map(
            (t) => RailEventCard(
              title: t.title,
              location: t.venue ?? '',
              date: t.trialDate,
              typeLabel: 'Trial',
              onTap: () => context.push('/trial-detail/${t.id}'),
            ),
          ),
      ...tournaments.items
          .take(4)
          .map(
            (t) => RailEventCard(
              title: t.title,
              location: t.venue ?? '',
              date: t.startDate,
              typeLabel: 'Tournament',
              onTap: () => context.push('/tournament-detail/${t.id}'),
            ),
          ),
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
      ...opportunities.items
          .take(4)
          .map(
            (o) => _OppRow(
              title: o.title,
              org: o.deadline == null
                  ? 'Open now'
                  : 'By ${o.deadline!.toLocal().toString().substring(0, 10)}',
              chip: o.type == 'sponsorship' ? 'Sponsorship' : 'Scholarship',
              onTap: () => context.push('/opportunity-detail/${o.id}'),
            ),
          ),
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
  const _OppRow({
    required this.title,
    required this.org,
    required this.chip,
    required this.onTap,
  });

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
              chip == 'Scholarship'
                  ? LucideIcons.graduationCap
                  : LucideIcons.briefcase,
              size: 20,
              color: AppColors.primaryDarker,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    org,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
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
