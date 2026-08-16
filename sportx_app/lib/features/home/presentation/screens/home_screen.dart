import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/providers/providers.dart';
import 'package:sportx_app/theme/colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(academiesProvider.notifier).refresh();
          ref.read(coachesProvider.notifier).refresh();
          ref.read(trialsProvider.notifier).refresh();
          ref.read(tournamentsProvider.notifier).refresh();
          ref.read(scholarshipsProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              pinned: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Hi ${user?.name?.split(' ').first ?? 'Athlete'}!',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.hand, color: Colors.amber, size: 20),
                          ],
                        ),
                        const SizedBox(height: 2),
                        profileAsync.when(
                          data: (data) {
                            final sports = data?['sports'] as List? ?? [];
                            final sportName = sports.isNotEmpty ? ((sports[0] as Map)['name'] as String?) ?? 'Sport' : 'Sport';
                            final ageGroup = (data?['age_group'] ?? data?['ageGroup']) as Map<String, dynamic>?;
                            final ageName = (ageGroup?['label'] ?? ageGroup?['name'] ?? 'Age Group') as String;
                            return Text(
                              '$sportName · $ageName',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            );
                          },
                          loading: () => const Text('Loading profile...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          error: (_, __) => const Text('Athlete', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/notifications'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.bell, color: AppColors.textSecondary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.push('/saved'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.heart, color: AppColors.textSecondary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  color: AppColors.background,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: GestureDetector(
                    onTap: () => context.push('/universal-search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.search, color: AppColors.textSecondary, size: 18),
                          SizedBox(width: 10),
                          Text('Search academies, trials, coaches...', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionHeader(title: 'Recommended for you', actionText: 'See all', onActionTap: () => context.push('/academies')),
                  const _RecommendedSection(),
                  
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Trials closing soon', actionText: 'See all', onActionTap: () => context.push('/trials')),
                  const _TrialSection(),
                  
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Upcoming Tournaments', actionText: 'See all', onActionTap: () => context.push('/tournaments')),
                  const _TournamentSection(),
                  
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'New Scholarships', actionText: 'See all', onActionTap: () => context.push('/scholarships')),
                  const _ScholarshipSection(),
                  
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onActionTap;

  const _SectionHeader({required this.title, required this.actionText, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          GestureDetector(
            onTap: onActionTap,
            child: Text(actionText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
          ),
        ],
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

    if (state.isLoading && state.items.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
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
      return const SizedBox(height: 180, child: Center(child: Text('No recommendations found')));
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          final isCoach = item.isCoach;
          return GestureDetector(
            onTap: () => isCoach ? context.push('/coach-detail/${item.id}') : context.push('/academy-detail/${item.id}'),
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                    ),
                    alignment: Alignment.center,
                    child: Icon(isCoach ? LucideIcons.user : LucideIcons.circleDot, color: AppColors.primary, size: 40),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('Cricket · ${item.subtitle}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(isCoach ? '₹800/session' : '₹2,000 – ₹5,000/mo', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
      return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
    }

    if (state.items.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: Text('No trials found')));
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: state.items.length.clamp(0, 5),
        itemBuilder: (context, i) {
          final item = state.items[i];
          return GestureDetector(
            onTap: () => context.push('/trial-detail/${item.id}'),
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.circleDot, color: AppColors.primary, size: 40),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(item.venue ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const Text('Aug 15 · ₹200', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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

class _TournamentSection extends ConsumerWidget {
  const _TournamentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tournamentsProvider);

    if (state.isLoading && state.items.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    }

    if (state.items.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: Text('No tournaments found')));
    }

    return Column(
      children: state.items.take(3).map((item) {
        return GestureDetector(
          onTap: () => context.push('/tournament-detail/${item.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.trophy, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('Aug 15–20 · ${item.venue ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Prize: ₹50,000', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF92400E))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    }

    if (state.items.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: Text('No scholarships found')));
    }

    return Column(
      children: state.items.take(3).map((item) {
        return GestureDetector(
          onTap: () => {},
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.graduationCap, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      const Text('Up to ₹50,000 · Deadline: Aug 30', style: TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('For U-18 athletes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF92400E))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
