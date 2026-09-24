import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
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
      await Future.wait([
        ref.read(academiesProvider.notifier).refresh(),
        ref.read(coachesProvider.notifier).refresh(),
        ref.read(trialsProvider.notifier).refresh(),
        ref.read(tournamentsProvider.notifier).refresh(),
        ref.read(scholarshipsProvider.notifier).refresh(),
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
                          label: 'Scholarships',
                          icon: LucideIcons.graduationCap,
                          tintBg: AppColors.yellowTint,
                          tintFg: const Color(0xFFF59E0B),
                          onTap: () => context.push('/scholarships')),
                      QuickTile(
                          label: 'Sponsorships',
                          icon: LucideIcons.briefcase,
                          tintBg: AppColors.infoLight,
                          tintFg: AppColors.info,
                          onTap: () => context.push('/sponsorships')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                      title: 'Recommended Athletes',
                      actionText: 'See all',
                      onActionTap: () => context.push('/discover')),
                  const _RecommendedSection(),
                  const SizedBox(height: 24),
                  SectionHeader(
                      title: 'Latest Opportunities',
                      actionText: 'See all',
                      onActionTap: () => context.push('/trials')),
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
    final state = ref.watch(scholarshipsProvider);

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
          subtitle: 'Up to ₹50,000 · Deadline: Aug 30',
          avatarText: 'S',
          trailing: const StatusPill(label: '18 days left', kind: PillKind.pending),
          onTap: () => context.push('/scholarship-detail/${item.id}'),
        );
      }).toList(),
    );
  }
}
