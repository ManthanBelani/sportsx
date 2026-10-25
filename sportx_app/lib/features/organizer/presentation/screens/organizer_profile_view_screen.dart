import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/features/organizer/presentation/widgets/organizer_kit.dart';
import 'package:sportx_app/features/trial/presentation/providers/unified_events_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Design board screen 6 · Organizer Profile — cover + avatar, name and role,
/// location, the stats row (Events · Participants · Collaborations), the
/// Edit Profile / Share buttons and the About / Events / Venues / Team / Media
/// tabs.
class OrganizerProfileViewScreen extends ConsumerStatefulWidget {
  const OrganizerProfileViewScreen({super.key});

  @override
  ConsumerState<OrganizerProfileViewScreen> createState() =>
      _OrganizerProfileViewScreenState();
}

class _OrganizerProfileViewScreenState
    extends ConsumerState<OrganizerProfileViewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 5,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const _typeLabels = {
    'federation': 'Federation / State Association',
    'club': 'Private Club',
    'other': 'Other',
  };

  static const _eventLabels = {
    'tournament': 'Tournaments',
    'trial': 'Trials',
    'championship': 'Championships',
    'camp': 'Camps',
    'league': 'Leagues',
    'workshop': 'Workshops',
    'sports_meet': 'Sports Meets',
    'marathon': 'Marathons',
    'other': 'Other',
  };

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myOrganizerProvider);
    final user = ref.watch(authProvider).user;
    final analytics = ref.watch(organizerAnalyticsProvider).valueOrNull;

    return async.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.surface,
        body: GenericListSkeleton(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.surface,
        appBar: SportXTopBar(
          title: 'Organization',
          showBack: true,
          onBack: () => context.pop(),
        ),
        body: Center(
          child: SecondaryButton(
            label: 'Retry',
            onPressed: () => ref.invalidate(myOrganizerProvider),
          ),
        ),
      ),
      data: (p) {
        final name =
            (p['organization_name']?.toString() ?? user?.name ?? 'Organization')
                .trim();
        final city =
            (p['city'] is Map ? p['city']['name']?.toString() : '') ?? '';
        final description = (p['description']?.toString() ?? '').trim();
        final website = (p['website']?.toString() ?? '').trim();
        final orgType =
            _typeLabels[p['org_type']?.toString()] ?? 'Event Organizer';
        final sportIds = <int>[
          for (final s in (p['sports'] as List? ?? []))
            if ((s is Map ? (s['id'] ?? s['sport_id']) : s) is num)
              ((s is Map ? (s['id'] ?? s['sport_id']) : s) as num).toInt(),
        ];
        final eventTypes = [
          for (final e in (p['event_types'] as List? ?? []))
            _eventLabels[e.toString()] ?? e.toString(),
        ];

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: CustomScrollView(
            slivers: [
              // Hero — cover + floating controls, built as a plain adapter
              // rather than a pinned SliverAppBar: a pinned appbar paints the
              // cover ON TOP of the content sliver that follows it, which used
              // to hide the overlapped logo avatar's upper half. Scrolling
              // simply carries the cover away; the tab bar below stays pinned.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 168,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover — org banner when the API resolved one, otherwise
                      // the board's dark stage backdrop.
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1B2430), Color(0xFF3A2B14)],
                          ),
                        ),
                        child: Icon(
                          LucideIcons.trophy,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 6,
                        left: 6,
                        child: _RoundIconButton(
                          icon: LucideIcons.arrowLeft,
                          onTap: () => context.pop(),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 6,
                        right: 6,
                        child: _RoundIconButton(
                          icon: LucideIcons.share2,
                          onTap: () => Share.share(
                            'Check out $name on SportX — sports events across ${city.isNotEmpty ? city : 'India'}.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Only the avatar overlaps the cover edge
                          // (translated up 34px). The name block must start
                          // BELOW the cover so it stays readable — translating
                          // the whole row pushed the title into the dark band.
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -34),
                                child: _LogoAvatar(
                                  photoUrl: user?.profilePhotoUrl,
                                  name: name,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildNameBlock(name, orgType, city),
                              ),
                            ],
                          ),
                            const SizedBox(height: 6),
                            // Stats row — Events · Participants · Collaborations
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 11,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  _stat(
                                    '${analytics?.totalEvents ?? 0}',
                                    'Events',
                                  ),
                                  _statDivider(),
                                  _stat(
                                    compactIndianNumber(
                                      analytics?.totalRegistrations ?? 0,
                                    ),
                                    'Participants',
                                  ),
                                  _statDivider(),
                                  _stat(
                                    ref
                                            .watch(organizerTeamProvider)
                                            .valueOrNull
                                            ?.length
                                            .toString() ??
                                        '—',
                                    'Collaborations',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton(
                                    label: 'Edit Profile',
                                    icon: LucideIcons.pencil,
                                    onPressed: () =>
                                        context.push('/organizer-profile-edit'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SecondaryButton(
                                    label: 'Share',
                                    icon: LucideIcons.share2,
                                    onPressed: () => Share.share(
                                      'Check out $name on SportX.',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.ink,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    indicatorColor: AppColors.yellow,
                    indicatorWeight: 2.5,
                    dividerColor: AppColors.border,
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Events'),
                      Tab(text: 'Venues'),
                      Tab(text: 'Team'),
                      // Media tab removed for organizers — uploading photos and
                      // videos is not part of the organizer flows anymore.
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _AboutTab(
                      description: description,
                      orgType: orgType,
                      sports: sportIds,
                      eventTypes: eventTypes,
                      city: city,
                      website: website,
                      registrationNumber:
                          (p['registration_number']?.toString() ?? '').trim(),
                    ),
                    const _EventsTab(),
                    const _VenuesTab(),
                    const _TeamTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNameBlock(String name, String orgType, String city) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(LucideIcons.badgeCheck, size: 17, color: AppColors.info),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          orgType,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              LucideIcons.mapPin,
              size: 12,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                city.isNotEmpty ? city : 'Location not set',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static const _dividerColor = Color(0xFFE8EAED);

  Widget _statDivider() =>
      Container(width: 1, height: 28, color: _dividerColor);

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: SportXShadows.e1,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 17, color: AppColors.ink),
      ),
    );
  }
}

class _LogoAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  const _LogoAvatar({this.photoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final has = (photoUrl ?? '').trim().isNotEmpty;
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.ink,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: SportXShadows.e2,
      ),
      alignment: Alignment.center,
      child: has
          ? ClipOval(
              child: Image.network(
                MediaUtils.resolveUrl(photoUrl!),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initial(),
              ),
            )
          : _initial(),
    );
  }

  Widget _initial() {
    final label = name.trim().isEmpty
        ? 'ORG'
        : name.trim().substring(0, 2).toUpperCase();
    return Text(
      label,
      style: GoogleFonts.sora(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.yellow,
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(color: AppColors.surface, child: tabBar);

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}

// ─── Tabs ───────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  final String description;
  final String orgType;
  final List<int> sports;
  final List<String> eventTypes;
  final String city;
  final String website;
  final String registrationNumber;

  const _AboutTab({
    required this.description,
    required this.orgType,
    required this.sports,
    required this.eventTypes,
    required this.city,
    required this.website,
    required this.registrationNumber,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Text(
          'About',
          style: GoogleFonts.sora(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description.isEmpty
              ? 'Add a short description in your profile so athletes know what you organize.'
              : description,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            height: 1.55,
            color: description.isEmpty
                ? AppColors.textTertiary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _detailRow(LucideIcons.building2, 'Organization Type', orgType),
        _detailRow(
          LucideIcons.trophy,
          'Event Type',
          eventTypes.isEmpty ? 'Not set yet' : eventTypes.join(', '),
        ),
        if (sports.isNotEmpty)
          _detailRow(
            LucideIcons.dumbbell,
            'Sports',
            sports.isEmpty ? 'Not set yet' : '${sports.length} sports linked',
          ),
        _detailRow(
          LucideIcons.mapPin,
          'Location',
          city.isEmpty ? 'Not set yet' : city,
        ),
        if (registrationNumber.isNotEmpty)
          _detailRow(
            LucideIcons.badgeCheck,
            'Registration No.',
            registrationNumber,
          ),
        _detailRow(
          LucideIcons.globe,
          'Website',
          website.isEmpty ? 'Add your website from Edit Profile' : website,
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryDarker),
          const SizedBox(width: 10),
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsTab extends ConsumerWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myEventsProvider);
    if (state.isLoading && state.events.isEmpty) {
      return const GenericListSkeleton(itemCount: 4);
    }
    if (state.events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SecondaryButton(
            label: 'Create your first event',
            icon: LucideIcons.plus,
            onPressed: () => context.push('/post-tournament'),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      children: [
        for (final e in state.events.take(8)) ...[
          OrgEventCard(
            title: e.name,
            start: e.startDate,
            end: e.endDate,
            location: e.locationLabel,
            sportName: e.sportName,
            bannerUrl: e.bannerUrl,
            registrationsOpen: e.registrationsOpen,
            registeredCount: e.registeredCount,
            onTap: () => context.push(
              e.isTournament
                  ? '/tournament-detail/${e.id}'
                  : '/trial-detail/${e.id}',
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextButton(
          onPressed: () => context.push('/my-tournaments'),
          child: const Text('View all my events'),
        ),
      ],
    );
  }
}

class _VenuesTab extends ConsumerWidget {
  const _VenuesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
      child: Column(
        children: [
          SecondaryButton(
            label: 'Add a venue',
            icon: LucideIcons.plus,
            onPressed: () => context.push('/post-facility'),
          ),
          const SizedBox(height: 14),
          Text(
            'Grounds, courts and facilities you list appear here — athletes can book them from your event pages.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SecondaryButton(
            label: 'Manage my venues',
            icon: LucideIcons.building2,
            onPressed: () => context.push('/facilities'),
          ),
        ],
      ),
    );
  }
}

class _TeamTab extends ConsumerWidget {
  const _TeamTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(organizerTeamProvider);
    return async.when(
      loading: () => const GenericListSkeleton(itemCount: 3),
      error: (_, _) => Center(
        child: Text(
          'Could not load your team right now.',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      data: (members) {
        if (members.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SecondaryButton(
                label: 'Add staff / organiser',
                icon: LucideIcons.userPlus,
                onPressed: () => context.push('/organizer-team'),
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
          children: [
            for (final m in members) ...[
              EntityRow(
                title: m.name,
                subtitle: '${m.roleLabel} · ${m.status}',
                avatarText: m.name.trim().isEmpty
                    ? 'T'
                    : m.name.trim()[0].toUpperCase(),
                onTap: () => context.push('/organizer-team'),
              ),
            ],
            TextButton(
              onPressed: () => context.push('/organizer-team'),
              child: const Text('Manage team'),
            ),
          ],
        );
      },
    );
  }
}
