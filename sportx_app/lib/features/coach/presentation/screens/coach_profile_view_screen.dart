import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/coach/presentation/providers/coach_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/social_links.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Design board screen 6 · Coach Profile (`4.15.00 PM`) — cover hero with the
/// COACH banner, verified name, "{Sport} Coach · qualification", location, the
/// About / Posts / Programs / Achievements pills and the About detail rows
/// (Experience, Specialization, Certifications, Languages...).
///
/// The board's Follow / Message buttons belong to the *public* profile; this is
/// the coach's own profile, so the same slots carry the owner actions —
/// Edit Profile (yellow) → `/coach-profile-edit` and Share.
class CoachProfileViewScreen extends ConsumerStatefulWidget {
  const CoachProfileViewScreen({super.key});

  @override
  ConsumerState<CoachProfileViewScreen> createState() =>
      _CoachProfileViewScreenState();
}

class _CoachProfileViewScreenState
    extends ConsumerState<CoachProfileViewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coachProvider);
    final user = ref.watch(authProvider).user;

    if (async.isLoading && async.coachProfile == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: CoachProfileViewSkeleton(),
      );
    }

    final coach = async.coachProfile;
    final name = (coach?.fullName ?? user?.name ?? 'Coach').trim();
    final sportName = coach?.sport?.name;
    final headline = [
      if (sportName != null && sportName.isNotEmpty) '$sportName Coach',
      if (coach?.specialization != null && coach!.specialization!.isNotEmpty)
        coach.specialization!,
    ].join(' · ');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () => ref.read(coachProvider.notifier).loadCoachProfile(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _cover(context, name)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -34),
                          child: _CoachAvatar(
                            photoUrl: coach?.profilePhotoUrl ?? user?.profilePhotoUrl,
                            name: name,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _nameBlock(name, headline, coach?.city?.name ?? coach?.location)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: 'Edit Profile',
                            icon: LucideIcons.pencil,
                            onPressed: () => context.push('/coach-profile-edit'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SecondaryButton(
                            label: 'Share',
                            icon: LucideIcons.share2,
                            onPressed: () => Share.share(
                              'Check out $name on SportX — Coach'
                              '${sportName != null ? ' ($sportName)' : ''}.',
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
                      fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  indicatorColor: AppColors.yellow,
                  indicatorWeight: 2.5,
                  dividerColor: AppColors.border,
                  tabs: const [
                    Tab(text: 'About'),
                    Tab(text: 'Posts'),
                    Tab(text: 'Programs'),
                    Tab(text: 'Achievements'),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AboutTab(
                    bio: coach?.bio ?? '',
                    experience: coach?.experience,
                    specialization: coach?.specialization,
                    certifications: async.certifications,
                    languages: coach?.languages,
                    city: coach?.city?.name ?? coach?.location,
                    socialLinks: coach?.socialLinks ?? const {},
                  ),
                  const _PostsTab(),
                  const _ProgramsTab(),
                  const _AchievementsTab(),
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF161C2D), AppColors.coach],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.medal,
                    size: 44, color: Colors.white.withValues(alpha: 0.72)),
                const SizedBox(width: 14),
                Text(
                  'COACH',
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
        ],
      ),
    );
  }

  Widget _nameBlock(String name, String headline, String? city) {
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
          headline.isEmpty ? 'Coach' : headline,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.coach,
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
                    fontSize: 11.5, color: AppColors.textSecondary),
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

class _CoachAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  const _CoachAvatar({this.photoUrl, required this.name});

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
          : const Icon(LucideIcons.userRound,
              size: 32, color: AppColors.yellow),
    );
  }

  Widget _initial() {
    final label = name.trim().isEmpty
        ? 'C'
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
  final String? experience;
  final String? specialization;
  final List<String> certifications;
  final List<String>? languages;
  final String? city;
  final Map<String, String> socialLinks;

  const _AboutTab({
    required this.bio,
    required this.experience,
    required this.specialization,
    required this.certifications,
    required this.languages,
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
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          bio.isEmpty
              ? 'Add a short bio in Edit Profile so athletes know how you train them.'
              : bio,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            height: 1.55,
            color: bio.isEmpty ? AppColors.textTertiary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        // Detail rows — only modeled data. The board's Age Group row is not in
        // the coach profile model, so it is deliberately not shown.
        if (experience != null && experience!.isNotEmpty)
          _detailRow(LucideIcons.briefcase, 'Experience',
              '${experience!.trim()} Years'),
        if (specialization != null && specialization!.isNotEmpty)
          _detailRow(LucideIcons.medal, 'Coaching Level',
              specialization!),
        if (certifications.isNotEmpty)
          _detailRow(
              LucideIcons.award, 'Certifications', certifications.join(', ')),
        if (languages != null && languages!.isNotEmpty)
          _detailRow(LucideIcons.languages, 'Languages', languages!.join(', ')),
        _detailRow(LucideIcons.mapPin, 'Location',
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
                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostsTab extends StatelessWidget {
  const _PostsTab();

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
            'Your posts and community activity appear in the activity hub.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProgramsTab extends StatelessWidget {
  const _ProgramsTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
      child: Column(
        children: [
          SecondaryButton(
            label: 'Open my training programs',
            icon: LucideIcons.dumbbell,
            onPressed: () => context.push('/my-programs'),
          ),
          const SizedBox(height: 14),
          Text(
            'Active, draft and past programs you coach are managed here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
      child: Column(
        children: [
          SecondaryButton(
            label: 'Open my achievements',
            icon: LucideIcons.award,
            onPressed: () => context.push('/achievements'),
          ),
          const SizedBox(height: 14),
          Text(
            'Certificates and achievements you have earned are listed here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
