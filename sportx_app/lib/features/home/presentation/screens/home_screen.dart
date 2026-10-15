import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/opportunity/presentation/providers/opportunity_provider.dart';
import 'package:sportx_app/features/social/presentation/providers/posts_provider.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/shared/providers/providers.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Athlete home — v2 skin (sportsx-design-v2/01-athlete/home.html).
/// Logic unchanged: same providers, same refresh, same routes.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final profileAsync = ref.watch(profileProvider);
    final firstName = (user?.name.split(' ').first ?? 'Athlete');
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A';

    Future<void> onRefresh() async {
      ref.invalidate(postsFeedProvider);
      await Future.wait<dynamic>([
        ref.read(academiesProvider.notifier).refresh(),
        ref.read(coachesProvider.notifier).refresh(),
        ref.read(trialsProvider.notifier).refresh(),
        ref.read(tournamentsProvider.notifier).refresh(),
        ref.read(opportunitiesProvider.notifier).refresh(),
      ]);
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.yellowDeep,
        onRefresh: onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.88),
              pinned: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: 64,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo.png'),
                        fit: BoxFit.cover,
                        onError: null,
                      ),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      text: 'Sport',
                      style: GoogleFonts.sora(
                          fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink),
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.yellow,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text('X',
                                style: GoogleFonts.sora(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SportXIconButton(icon: LucideIcons.search, onTap: () => context.push('/universal-search')),
                  const SizedBox(width: 8),
                  SportXIconButton(
                      icon: LucideIcons.bell, badge: 3, onTap: () => context.push('/notifications')),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // v2 .greet
                  profileAsync.when(
                    data: (data) => GreetCard(
                      title: 'Hi, $firstName!',
                      subtitle: 'Complete your profile to get discovered',
                      progress: 0.6,
                      avatarText: initial,
                    ),
                    loading: () => const GreetCard(
                      title: 'Hi!',
                      subtitle: 'Complete your profile to get discovered',
                      progress: 0.6,
                      avatarText: 'A',
                    ),
                    error: (_, _) => GreetCard(
                      title: 'Hi, $firstName!',
                      subtitle: 'Complete your profile to get discovered',
                      progress: 0.6,
                      avatarText: initial,
                    ),
                  ),
                  // v2 .tiles
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.3,
                    children: [
                      QuickTile(
                          label: 'Trials',
                          icon: LucideIcons.trophy,
                          tintBg: const Color(0xFFFEE2E2),
                          tintFg: AppColors.error,
                          onTap: () => context.push('/trials')),
                      QuickTile(
                          label: 'Tournaments',
                          icon: LucideIcons.medal,
                          tintBg: const Color(0xFFECE9FF),
                          tintFg: AppColors.coach,
                          onTap: () => context.push('/tournaments')),
                      QuickTile(
                          label: 'Opportunities',
                          icon: LucideIcons.graduationCap,
                          tintBg: AppColors.yellowTint,
                          tintFg: const Color(0xFFF59E0B),
                          onTap: () => context.push('/opportunities')),
                      QuickTile(
                          label: 'Saved',
                          icon: LucideIcons.bookmark,
                          tintBg: AppColors.infoLight,
                          tintFg: AppColors.info,
                          onTap: () => context.push('/saved')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _FeedSection(),
                  const SizedBox(height: 24),
                  SectionHeader(
                      title: 'Recommended Academies & Coaches',
                      actionText: 'See all',
                      onActionTap: () => context.push('/discover')),
                  const _RecommendedSection(),
                  const SizedBox(height: 24),
                  SectionHeader(
                      title: 'Latest Opportunities',
                      actionText: 'See all',
                      onActionTap: () => context.push('/opportunities')),
                  const _TrialSection(),
                  const SizedBox(height: 8),
                  const _TournamentSection(),
                  const SizedBox(height: 8),
                  const _ScholarshipSection(),
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

class _RecommendedSection extends ConsumerWidget {
  const _RecommendedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(academiesProvider);
    final coachesState = ref.watch(coachesProvider);

    final isLoading = (state.isLoading && state.items.isEmpty) || (coachesState.isLoading && coachesState.items.isEmpty);
    if (isLoading) {
      return SizedBox(
        height: 190,
        child: ShimmerSkeleton(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, _) => Container(
              width: 148,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border)),
              child: const Column(children: [
                SkeletonBox(width: double.infinity, height: 96, borderRadius: 16),
              ]),
            ),
          ),
        ),
      );
    }

    final items = <({String id, String title, String subtitle, bool isCoach})>[
      ...state.items.take(3).map((a) => (
            id: a.id.toString(),
            title: a.name,
            subtitle: a.city?.name ?? '',
            isCoach: false,
          )),
      ...coachesState.items.take(2).map((c) => (
            id: c.id.toString(),
            title: c.fullName,
            subtitle: '${c.experience ?? 0} yrs exp',
            isCoach: true,
          )),
    ];

    if (items.isEmpty) {
      return const SizedBox(height: 160, child: Center(child: Text('No recommendations found')));
    }

    // v2 .rail-card
    return SizedBox(
      height: 196,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => item.isCoach
                ? context.push('/coach-detail/${item.id}')
                : context.push('/academy-detail/${item.id}'),
            child: Container(
              width: 148,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
                boxShadow: SportXShadows.e1,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    height: 96,
                    color: const Color(0xFF14161A),
                    alignment: Alignment.center,
                    child: Icon(
                        item.isCoach ? LucideIcons.user : LucideIcons.building2,
                        color: Colors.white70,
                        size: 32),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                    child: Column(
                      children: [
                        Text(item.title,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 2),
                        Text(item.subtitle,
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          label: 'Follow',
                          small: true,
                          onPressed: () => item.isCoach
                              ? context.push('/coach-detail/${item.id}')
                              : context.push('/academy-detail/${item.id}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrialSection extends ConsumerWidget {
  const _TrialSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trialsProvider);

    if (state.isLoading && state.items.isEmpty) {
      return SizedBox(
        height: 200,
        child: ShimmerSkeleton(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => Container(
              width: 280,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border)),
              child: const Column(children: [
                SkeletonBox(width: double.infinity, height: 100, borderRadius: 18),
              ]),
            ),
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return const SizedBox(height: 120, child: Center(child: Text('No trials found')));
    }

    return Column(
      children: state.items.take(2).map((item) {
        return OppCard(
          title: item.title,
          org: item.venue ?? '',
          featured: item == state.items.first,
          meta: const [
            (icon: LucideIcons.calendar, text: '15 Oct 2026'),
            (icon: LucideIcons.mapPin, text: 'Ahmedabad'),
            (icon: LucideIcons.user, text: 'U-19'),
          ],
          onTap: () => context.push('/trial-detail/${item.id}'),
        );
      }).toList(),
    );
  }
}

class _TournamentSection extends ConsumerWidget {
  const _TournamentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tournamentsProvider);

    if (state.isLoading && state.items.isEmpty) {
      return ShimmerSkeleton(
        child: Column(
          children: List.generate(
              2,
              (_) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Row(children: [
                      SkeletonBox(width: 50, height: 50, borderRadius: 15),
                    ]),
                  )),
        ),
      );
    }

    if (state.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: state.items.take(2).map((item) {
        return EntityRow(
          title: item.title,
          subtitle: '${item.venue ?? ''} · Prize: ₹50,000',
          avatarText: 'T',
          onTap: () => context.push('/tournament-detail/${item.id}'),
        );
      }).toList(),
    );
  }
}

class _ScholarshipSection extends ConsumerWidget {
  const _ScholarshipSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(opportunitiesProvider);

    if (state.isLoading && state.items.isEmpty) {
      return ShimmerSkeleton(
        child: Column(
          children: List.generate(
              2,
              (_) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Row(children: [
                      SkeletonBox(width: 50, height: 50, borderRadius: 15),
                    ]),
                  )),
        ),
      );
    }

    if (state.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: state.items.take(2).map((item) {
        final daysLeft = item.deadline?.difference(DateTime.now()).inDays;
        final subtitle = [
          if (item.amount != null)
            'Up to ₹${item.amount!.toStringAsFixed(item.amount! % 1 == 0 ? 0 : 2)}',
          if (item.deadline != null)
            'Deadline: ${item.deadline!.day}/${item.deadline!.month}',
        ].join(' · ');
        return EntityRow(
          title: item.title,
          subtitle: subtitle.isEmpty ? (item.type) : subtitle,
          avatarText: 'O',
          trailing: daysLeft != null
              ? StatusPill(
                  label: daysLeft < 0
                      ? 'Closed'
                      : daysLeft == 0
                          ? 'Last day'
                          : '$daysLeft days left',
                  kind: PillKind.pending)
              : null,
          onTap: () => context.push('/opportunity-detail/${item.id}'),
        );
      }).toList(),
    );
  }
}

class _FeedSection extends ConsumerWidget {
  const _FeedSection();

  Future<void> _toggleLike(WidgetRef ref, String postId, bool currentlyLiked) async {
    if (currentlyLiked) {
      await unlikePost(ref, postId);
    } else {
      await togglePostLike(ref, postId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(postsFeedProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Latest from the Community',
          actionText: 'See all',
          onActionTap: () => context.push('/community'),
        ),
        if (feed.isLoading && feed.value == null)
          const _FeedSkeleton()
        else if (feed.hasError)
          _FeedRetry(onRetry: () => ref.invalidate(postsFeedProvider))
        else if (!feed.hasValue || feed.value!.isEmpty)
          const SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'Be the first to post — share an update from your training.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...feed.value!.take(2).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PostCard(
                  post: p,
                  onLike: () => _toggleLike(ref, p.id, p.liked),
                  onTap: () => context.push('/post-detail/${p.id}'),
                ),
              )),
      ],
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: ShimmerSkeleton(
        child: Column(
          children: [
            _SkeletonPost(),
            SizedBox(height: 12),
            _SkeletonPost(),
          ],
        ),
      ),
    );
  }
}

class _FeedRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _FeedRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(LucideIcons.refreshCw, size: 16),
        label: const Text('Couldn\'t load feed — tap to retry'),
      ),
    );
  }
}

class _SkeletonPost extends StatelessWidget {
  const _SkeletonPost();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            SkeletonBox(width: 36, height: 36, borderRadius: 99),
            SizedBox(width: 10),
            SkeletonBox(width: 120, height: 12, borderRadius: 6),
          ]),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 12, borderRadius: 6),
          SizedBox(height: 6),
          SkeletonBox(width: 220, height: 12, borderRadius: 6),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final SocialPost post;
  final VoidCallback onLike;
  final VoidCallback onTap;
  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = post.authorAvatar;
    final image = post.imageUrl;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.yellowTint,
                    backgroundImage: (avatar != null && avatar.isNotEmpty)
                        ? NetworkImage(MediaUtils.resolveUrl(avatar))
                        : null,
                    child: (avatar == null || avatar.isEmpty)
                        ? Text(
                            post.authorName.isNotEmpty
                                ? post.authorName[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          post.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        if ((post.createdAt ?? '').isNotEmpty)
                          Text(
                            _humanizeTime(post.createdAt!),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if ((post.body ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text(
                  post.body!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.ink,
                  ),
                ),
              ),
            if (image != null && image.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  MediaUtils.resolveUrl(image),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.surface,
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.image,
                        color: AppColors.textTertiary, size: 32),
                  ),
                ),
              ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.borderSoft,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  _ActionButton(
                    icon: post.liked ? LucideIcons.heart : LucideIcons.heart,
                    iconColor:
                        post.liked ? Colors.redAccent : AppColors.textSecondary,
                    filled: post.liked,
                    label: _compactNumber(post.likesCount),
                    onTap: onLike,
                  ),
                  _ActionButton(
                    icon: LucideIcons.messageCircle,
                    iconColor: AppColors.textSecondary,
                    label: _compactNumber(post.commentsCount),
                    onTap: onTap,
                  ),
                  const Spacer(),
                  _ActionButton(
                    icon: LucideIcons.share2,
                    iconColor: AppColors.textSecondary,
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final bool filled;
  final String? label;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.label,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: iconColor,
      ),
      icon: Icon(icon, size: 18, color: iconColor,
          fill: filled ? 1.0 : null),
      label: label == null
          ? const SizedBox.shrink()
          : Text(label!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              )),
    );
  }
}

String _humanizeTime(String raw) {
  final dt = DateTime.tryParse(raw);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.day}/${dt.month}';
}

String _compactNumber(int n) {
  if (n < 1000) return n.toString();
  if (n < 10000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '${(n / 1000).round()}K';
}
