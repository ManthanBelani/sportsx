import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/social/presentation/providers/posts_provider.dart';
import 'package:sportx_app/features/social/presentation/widgets/community_feed.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';

/// v2 S.9 / v3 S.12 — Community feed: full post stream, create-post
/// FAB, and a sticky composer at the bottom (mockup 'New post' S.9).
class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(postsFeedProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        title: Text('Community',
            style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: AppColors.textPrimary),
            onPressed: () => ref.invalidate(postsFeedProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.yellowDeep,
        onRefresh: () async => ref.invalidate(postsFeedProvider),
        child: feed.when(
          loading: () => const _CommunitySkeleton(),
          error: (e, _) => _CommunityError(
            message: e.toString(),
            onRetry: () => ref.invalidate(postsFeedProvider),
          ),
          data: (posts) {
            if (posts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          const Icon(LucideIcons.users,
                              size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text(
                            'No posts yet',
                            style: GoogleFonts.sora(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Be the first to share an update with the community.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => context.push('/create-post'),
                            icon: const Icon(LucideIcons.plus, size: 18),
                            label: const Text('Create a post'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: posts.length,
              itemBuilder: (context, i) {
                final p = posts[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CommunityPostCard(
                    post: p,
                    onLike: () => p.liked
                        ? unlikePost(ref, p.id)
                        : togglePostLike(ref, p.id),
                    onComment: () => context.push('/post-detail/${p.id}'),
                    onOpen: () => context.push('/post-detail/${p.id}'),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-post'),
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.ink,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: Text(
          'New Post',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _CommunitySkeleton extends StatelessWidget {
  const _CommunitySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ShimmerSkeleton(
          child: Column(
            children: [
              _PostSkel(),
              SizedBox(height: 12),
              _PostSkel(),
              SizedBox(height: 12),
              _PostSkel(),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostSkel extends StatelessWidget {
  const _PostSkel();

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
            SkeletonBox(width: 140, height: 12, borderRadius: 6),
          ]),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 12, borderRadius: 6),
          SizedBox(height: 6),
          SkeletonBox(width: 200, height: 12, borderRadius: 6),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 160, borderRadius: 12),
        ],
      ),
    );
  }
}

class _CommunityError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _CommunityError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Icon(LucideIcons.triangleAlert,
                    color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                Text(
                  "Couldn't load community feed",
                  style: GoogleFonts.sora(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
