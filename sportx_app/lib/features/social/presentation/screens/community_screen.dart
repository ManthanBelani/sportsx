import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/connections/presentation/providers/follow_block_provider.dart';
import 'package:sportx_app/shared/providers/providers.dart';
import 'package:sportx_app/shared/providers/role_config_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/home_kit.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/features/social/presentation/providers/groups_provider.dart';
import 'package:sportx_app/features/social/presentation/providers/posts_provider.dart';
import 'package:sportx_app/features/social/presentation/widgets/community_feed.dart';

/// S.12 Community — Network / Groups / Events / Feed tabs per design
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

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
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Role-specific shortcuts for the community hub.
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
          labels: const ['Network', 'Groups', 'Events', 'Feed'],
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
        else if (_tab == 2)
          const _EventsSection()
        else
          const _FeedSection(),
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
          loading: () => const _SuggestedSkeleton(),
          error: (_, _) => emptyHint('Could not load suggestions right now.'),
          data: (state) {
            if (state.isEmpty) return emptyHint('More athletes will appear here as they join SportX.');
            return Column(
              children: [
                for (final a in state.take(4))
                  _SuggestedFollowRow(
                    athleteId: a['id']?.toString() ?? '',
                    name: (a['full_name'] ?? a['name'] ?? 'Athlete').toString(),
                    role: a['sport'] is Map && a['sport']['name'] != null
                        ? a['sport']['name'].toString()
                        : 'Athlete',
                    photoUrl: _photo((a['profile_photo_url'] ?? '').toString()),
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

class _SuggestedSkeleton extends StatelessWidget {
  const _SuggestedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SkeletonWidget.rectangular(height: 70, radius: 14),
      )),
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

// ─── Groups tab (Dynamic) ─────────────────────────────────────────────────────

class _GroupsSection extends ConsumerWidget {
  const _GroupsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeadV3(
          title: 'Popular groups',
          actionText: 'See all',
          onActionTap: () => context.push('/groups'),
        ),
        groupsAsync.when(
          loading: () => _GroupsSkeleton(),
          error: (e, _) => Column(
            children: [
              emptyHint('Could not load groups.'),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref.invalidate(groupsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return emptyHint('No groups yet. Be the first to create one!');
            }
            return Column(
              children: [
                for (final g in groups.take(6)) _GroupCard(group: g),
                if (groups.length > 6)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: OutlinedButton(
                      onPressed: () => context.push('/groups'),
                      child: Text('View all ${groups.length} groups'),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GroupsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: SkeletonWidget.rectangular(height: 70, radius: 16),
      )),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final Group group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeColors = {
      'coaching': AppColors.coach,
      'athletes': AppColors.academy,
      'trials': AppColors.organizer,
      'general': AppColors.primary,
    };
    final typeIcons = {
      'coaching': LucideIcons.dumbbell,
      'athletes': LucideIcons.users,
      'trials': LucideIcons.flag,
      'general': LucideIcons.usersRound,
    };

    return Container(
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
              color: (typeColors[group.type] ?? AppColors.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              typeIcons[group.type] ?? LucideIcons.usersRound,
              size: 20,
              color: typeColors[group.type] ?? AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ),
                    if (group.memberCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.users, size: 10, color: AppColors.textTertiary),
                            const SizedBox(width: 2),
                            Text(
                              '${group.memberCount}',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(group.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SportXChip(
            label: group.isMember ? 'Joined' : 'Join',
            icon: group.isMember ? LucideIcons.check : LucideIcons.plus,
            selected: group.isMember,
            onTap: () async {
              if (group.isMember) {
                await leaveGroup(ref, group.id);
              } else {
                await joinGroup(ref, group.id);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─── Events tab ───────────────────────────────────────────────────────────────

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

// ─── Feed tab ─────────────────────────────────────────────────────────────────

class _FeedSection extends ConsumerWidget {
  const _FeedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _FeedSectionContent();
  }
}

class _FeedSectionContent extends StatefulWidget {
  const _FeedSectionContent();

  @override
  State<_FeedSectionContent> createState() => _FeedSectionContentState();
}

class _FeedSectionContentState extends State<_FeedSectionContent> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Could trigger pagination here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, WidgetRef ref, _) {
        // Real feed only — the community used to fall back to mock posts
        // ("Rohit Sharma", …) when the API had nothing, which showed fake
        // content to real users.
        final postsAsync = ref.watch(filteredPostsFeedProvider(''));

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(filteredPostsFeedProvider(''));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeadV3(
                title: 'Community Feed',
                actionText: 'Create Post',
                onActionTap: () => context.push('/create-post'),
              ),
              postsAsync.when(
                loading: () => _FeedSkeleton(),
                error: (e, _) => Column(
                  children: [
                    emptyHint('Could not load feed.'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        ref.invalidate(filteredPostsFeedProvider(''));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
                data: (posts) {
                  if (posts.isEmpty) {
                    return Column(
                      children: [
                        emptyHint('No posts yet. Be the first to share!'),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Create Post',
                          icon: LucideIcons.plus,
                          onPressed: () => context.push('/create-post'),
                        ),
                        const SizedBox(height: 100),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: posts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final post = posts[index];
                      return CommunityPostCard(
                        post: post,
                        onLike: () => togglePostLike(ref, post.id),
                        onComment: () => context.push('/post-detail/${post.id}'),
                        onOpen: () => context.push('/post-detail/${post.id}'),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              );
            },
          ),
        ],
      ),
    );
  });
  }
}

class _FeedSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SkeletonWidget.rectangular(height: 180, radius: 16),
      )),
    );
  }
}

String _photo(String raw) => raw.isNotEmpty ? MediaUtils.resolveUrl(raw) : '';

/// Suggested-athlete row whose Follow CTA actually follows the athlete's
/// profile (C3). The card body still opens the profile; only the button follows.
class _SuggestedFollowRow extends ConsumerStatefulWidget {
  final String athleteId;
  final String name;
  final String role;
  final String? photoUrl;
  const _SuggestedFollowRow({
    required this.athleteId,
    required this.name,
    required this.role,
    this.photoUrl,
  });

  @override
  ConsumerState<_SuggestedFollowRow> createState() => _SuggestedFollowRowState();
}

class _SuggestedFollowRowState extends ConsumerState<_SuggestedFollowRow> {
  bool _busy = false;
  bool _followed = false;

  Future<void> _toggle() async {
    if (_busy || widget.athleteId.isEmpty) return;
    setState(() {
      _busy = true;
      _followed = !_followed; // optimistic
    });
    final ok = _followed
        ? await followProfile(ref, 'athlete', widget.athleteId)
        : await unfollowProfile(ref, 'athlete', widget.athleteId);
    if (!mounted) return;
    if (!ok) {
      setState(() => _followed = !_followed);
      SnackBarUtils.showError(context, 'Could not ${_followed ? 'follow' : 'unfollow'}');
    } else {
      SnackBarUtils.showSuccess(context, _followed ? 'Following' : 'Unfollowed');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return PersonRowCard(
      name: widget.name,
      role: widget.role,
      photoUrl: widget.photoUrl,
      ctaLabel: _followed ? 'Following' : 'Follow',
      onTap: () => context.push('/view-profile', extra: {'type': 'athlete', 'id': widget.athleteId}),
      onCtaTap: _toggle,
    );
  }
}