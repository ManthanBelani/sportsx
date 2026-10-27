import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_shortlist_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/talent_scout_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/social_links.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';

/// Design board screen 6 · Scout Profile (`4.17.25 PM`) — SCOUT cover hero,
/// name + verified, "Talent Scout · city", Edit Profile (yellow) / Share,
/// and the About / Shortlisted Talents / Reports / Activity tabs.
///
/// The inline edit form lives in `/scout-profile/edit`
/// ([TalentScoutProfileEditScreen] in
/// `talent_scout_profile_edit_screen.dart`).
class TalentScoutProfileScreen extends ConsumerStatefulWidget {
  const TalentScoutProfileScreen({super.key});

  @override
  ConsumerState<TalentScoutProfileScreen> createState() =>
      _TalentScoutProfileScreenState();
}

class _TalentScoutProfileScreenState
    extends ConsumerState<TalentScoutProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(talentScoutProvider);
    final user = ref.watch(authProvider).user;
    final meta = ref.watch(metaProvider);

    if (async.isLoading && async.profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: GenericListSkeleton(),
      );
    }

    final profile = async.profile;
    final cities = meta.cities;
    String? cityName;
    for (final c in cities) {
      if (c.id == profile?.cityId) {
        cityName = c.name;
        break;
      }
    }
    final sports = meta.sports;
    final sportNames = sports
        .where((s) => (profile?.sportsSpecialization ?? const []).contains(s.id))
        .map((s) => s.name)
        .toList();
    final name = (user?.name ?? 'Talent Scout').trim();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(talentScoutProvider.notifier).loadProfile(),
        child: CustomScrollView(
          slivers: [
            // Cover — "SCOUT" banner over a dark backdrop (matches screen 6).
            SliverToBoxAdapter(child: _cover(context, name)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar overlaps the cover; the name block stays below it
                    // (same layout as the organizer profile view).
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -34),
                          child: _ScoutAvatar(
                            photoUrl: profile?.photoUrl ?? user?.profilePhotoUrl,
                            name: name,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _nameBlock(name, cityName)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: 'Edit Profile',
                            icon: LucideIcons.pencil,
                            onPressed: () => context.push('/scout-profile/edit'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SecondaryButton(
                            label: 'Share',
                            icon: LucideIcons.share2,
                            onPressed: () => Share.share(
                              'Check out $name on SportX — Talent Scout'
                              '${cityName != null ? ' in $cityName' : ''}.',
                            ),
                          ),
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
                    Tab(text: 'Shortlisted Talents'),
                    Tab(text: 'Reports'),
                    Tab(text: 'Activity'),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AboutTab(
                    bio: profile?.bio ?? '',
                    organization: profile?.organization ?? '',
                    affiliation: profile?.affiliation ?? '',
                    sportNames: sportNames,
                    experienceYears: profile?.experienceYears,
                    city: cityName,
                    socialLinks: profile?.socialLinks ?? const {},
                  ),
                  const _ShortlistTab(),
                  const _ReportsTab(),
                  const _ActivityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover(BuildContext context, String name) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: top + 168,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [Color(0xFF161C2D), AppColors.scout],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.binoculars,
                    size: 46, color: Colors.white.withValues(alpha: 0.72)),
                const SizedBox(width: 14),
                Text(
                  'SCOUT',
                  style: GoogleFonts.sora(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: top + 6,
            left: 6,
            child: _RoundIconButton(
              icon: LucideIcons.arrowLeft,
              onTap: () => context.pop(),
            ),
          ),
          Positioned(
            top: top + 6,
            right: 6,
            child: _RoundIconButton(
              icon: LucideIcons.share2,
              onTap: () => Share.share('Check out $name on SportX — Talent Scout.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameBlock(String name, String? city) {
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
        const SizedBox(height: 4),
        Text(
          'Talent Scout',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.scout,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(LucideIcons.mapPin, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                (city == null || city.isEmpty) ? 'Location not set' : city,
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

class _ScoutAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  const _ScoutAvatar({this.photoUrl, required this.name});

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
          : const Icon(LucideIcons.userSearch, size: 32, color: AppColors.yellow),
    );
  }

  Widget _initial() {
    final label = name.trim().isEmpty
        ? 'SC'
        : name.trim().substring(0, 1).toUpperCase();
    return Text(
      label,
      style: GoogleFonts.sora(
        fontSize: 26,
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(color: AppColors.surface, child: tabBar);

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}

// ─── Tabs ───────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  final String bio;
  final String organization;
  final String affiliation;
  final List<String> sportNames;
  final int? experienceYears;
  final String? city;
  final Map<String, String> socialLinks;

  const _AboutTab({
    required this.bio,
    required this.organization,
    required this.affiliation,
    required this.sportNames,
    required this.experienceYears,
    required this.city,
    required this.socialLinks,
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
          bio.isEmpty
              ? 'Add a short bio in Edit Profile so athletes and organizations know who you scout for.'
              : bio,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            height: 1.55,
            color: bio.isEmpty ? AppColors.textTertiary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        // Detail rows — only real, modeled data. Rating/Languages/Availability
        // from the board are not in the scout profile model, so they are
        // deliberately not shown (no fabricated stats).
        _detailRow(LucideIcons.building2, 'Organization',
            organization.isEmpty ? 'Not set yet' : organization),
        if (affiliation.isNotEmpty)
          _detailRow(LucideIcons.handshake, 'Affiliation', affiliation),
        _detailRow(
            LucideIcons.dumbbell,
            'Sports Focus',
            sportNames.isEmpty ? 'Not set yet' : sportNames.join(', ')),
        _detailRow(LucideIcons.briefcase, 'Experience',
            experienceYears == null ? 'Not set yet' : '$experienceYears+ Years'),
        _detailRow(
            LucideIcons.mapPin,
            'Location',
            (city ?? '').isEmpty ? 'Not set yet' : city!),
        if (socialLinks.isNotEmpty) ...[
          const SizedBox(height: 4),
          SocialLinksRow(links: socialLinks),
        ],
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

class _ShortlistTab extends ConsumerWidget {
  const _ShortlistTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scoutShortlistProvider);
    if (state.isLoading && state.items.isEmpty) {
      return const GenericListSkeleton(itemCount: 4);
    }
    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SecondaryButton(
                label: 'Discover talents to shortlist',
                icon: LucideIcons.search,
                onPressed: () => context.push('/scout-discovery'),
              ),
              const SizedBox(height: 12),
              Text(
                'Athletes you shortlist appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      children: [
        for (final e in state.items.take(6)) ...[
          EntityRow(
            title: e.athlete.fullName,
            subtitle: [
              if (e.athlete.sports.isNotEmpty) e.athlete.sports.first,
              if (e.athlete.ageGroupName != null) e.athlete.ageGroupName!,
            ].join(' · '),
            avatarText: e.athlete.fullName.trim().isEmpty
                ? 'A'
                : e.athlete.fullName.trim()[0].toUpperCase(),
            onTap: () => context.push('/scout-shortlist'),
          ),
        ],
        TextButton(
          onPressed: () => context.push('/scout-shortlist'),
          child: const Text('View all shortlisted talents'),
        ),
      ],
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
      child: Column(
        children: [
          SecondaryButton(
            label: 'Open scouting reports',
            icon: LucideIcons.fileText,
            onPressed: () => context.push('/observations'),
          ),
          const SizedBox(height: 14),
          Text(
            'Structured evaluations and quick observations you log for athletes live here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          SecondaryButton(
            label: 'Create a talent report',
            icon: LucideIcons.plus,
            onPressed: () => context.push('/talent-report'),
          ),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
      child: Column(
        children: [
          SecondaryButton(
            label: 'Open activity hub',
            icon: LucideIcons.activity,
            onPressed: () => context.push('/activity-hub'),
          ),
          const SizedBox(height: 14),
          Text(
            'Your recent actions across SportX — posts, connections and opportunities.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
