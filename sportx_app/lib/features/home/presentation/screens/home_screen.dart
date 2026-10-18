import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/opportunity/presentation/providers/opportunity_provider.dart';
import 'package:sportx_app/features/social/presentation/providers/posts_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/home_kit.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/providers/providers.dart';
import 'package:sportx_app/theme/colors.dart';

/// AT.1 Athlete home â€” v3 skin (sportsx-design-v3/v2/index.html, homeShell()).
/// Layout mirrors the prototype: header â†’ greet card â†’ role line â†’
/// Leaderboard â†’ quick tiles â†’ feed tabs + post â†’ recommended rail.
/// Logic unchanged: same providers, same refresh, same routes.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final profileAsync = ref.watch(profileProvider);
    final firstName = (user?.name.split(' ').first ?? 'Athlete');

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
              backgroundColor: Colors.white.withValues(alpha: 0.96),
              pinned: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: 68,
              titleSpacing: 16,
              title: Row(
                children: [
                  const Expanded(child: SportXWordmark()),
                  const HomeHeaderActions(),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Greet card (avatar photo when the profile has one).
                  profileAsync.maybeWhen(
                    data: (data) {
                      final photo = (data?['profile_photo_url'] ?? '').toString();
                      return GreetCardV3(
                        greeting: greetingFor(DateTime.now()),
                        name: 'Hi, $firstName!',
                        avatarInitial: firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A',
                        subtitle: 'Complete your profile to get more opportunities',
                        progress: 0.6,
                        ctaLabel: 'Complete Now',
                        onCta: () => context.push('/profile-completion'),
                        avatarUrl: photo.isNotEmpty ? photo : null,
                      );
                    },
                    orElse: () => GreetCardV3(
                      greeting: greetingFor(DateTime.now()),
                      name: 'Hi, $firstName!',
                      avatarInitial: firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A',
                      subtitle: 'Complete your profile to get more opportunities',
                      progress: 0.6,
                      ctaLabel: 'Complete Now',
                      onCta: () => context.push('/profile-completion'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  RoleLine(
                    badgeLabel: 'Athlete',
                    location: _locationLabel(profileAsync),
                  ),
                  const LeaderboardSectionV3(),

                  // .quick-grid â€” Opportunities + Academy/Coach & Training Centre.
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.62,
                    children: [
                      QuickTileV3(
                        title: 'Opportunities',
                        subtitle: 'Trials Â· Tournaments Â· Scholarships Â· Sponsorships',
                        icon: LucideIcons.trophy,
                        iconBg: AppColors.yellowTint,
                        iconFg: AppColors.primaryDarker,
                        onTap: () => context.push('/opportunities'),
                        subtiles: const [
                          (label: 'Trials', route: '/trials'),
                          (label: 'Tournaments', route: '/tournaments'),
                          (label: 'Scholarships', route: '/scholarships'),
                          (label: 'Sponsorships', route: '/sponsorships'),
                        ],
                      ),
                      QuickTileV3(
                        title: 'Academy, Coach & Training Centre',
                        subtitle: 'Find Academies Â· Coaches Â· Training Centres',
                        icon: LucideIcons.school,
                        iconBg: AppColors.infoLight,
                        iconFg: AppColors.info,
                        onTap: () => context.push('/academies'),
                        subtiles: const [
                          (label: 'Academies', route: '/academies'),
                          (label: 'Coaches', route: '/coaches'),
                          (label: 'Training', route: '/my-programs'),
                          (label: 'Centres', route: '/sports-venues'),
                        ],
                      ),
                    ],
                  ),
                  const V3FeedPreview(),
                  const SizedBox(height: 18),
                  SectionHeadV3(
                      title: 'Recommended Athletes for You',
                      actionText: 'See all',
                      onActionTap: () => context.push('/discover')),
                  const _RecommendedRail(),
                  const SizedBox(height: 96),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _locationLabel(AsyncValue<Map<String, dynamic>?> profile) {
    final data = profile.valueOrNull;
    if (data == null) return null;
    final city = data['city'];
    if (city is Map && city['name'] != null) return city['name'].toString();
    if (city is String && city.isNotEmpty) return city;
    return null;
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Recommended people rail (v3 .rail / .acard)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RecommendedRail extends ConsumerWidget {
  const _RecommendedRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athletes = ref.watch(athletesProvider);
    return athletes.when(
      loading: () => SizedBox(
        height: 184,
        child: ShimmerSkeleton(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
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
        ),
      ),
      error: (_, _) => emptyHint('Could not load recommendations right now.'),
      data: (rows) {
        final picks = rows.take(6).toList();
        if (picks.isEmpty) return emptyHint('Recommended athletes will show here as more join.');
        return SizedBox(
          height: 186,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: picks.length,
            itemBuilder: (_, i) {
              final a = picks[i];
              final name = (a['full_name'] ?? a['name'] ?? 'Athlete').toString();
              String role = 'Athlete';
              if (a['sport'] is Map && a['sport']['name'] != null) {
                role = a['sport']['name'].toString();
              } else if (a['sports'] is List && (a['sports'] as List).isNotEmpty) {
                role = ((a['sports'] as List).first as Map)['name']?.toString() ?? 'Athlete';
              }
              final photo = (a['profile_photo_url'] ?? '').toString();
              final id = a['id']?.toString() ?? '';
              return RailPersonCard(
                name: name,
                role: role,
                photoUrl: photo.isNotEmpty ? MediaUtils.resolveUrl(photo) : null,
                ctaLabel: 'View',
                onTap: () => context.push('/view-profile', extra: {'type': 'athlete', 'id': id}),
              );
            },
          ),
        );
      },
    );
  }
}
