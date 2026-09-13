import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/talent_scout_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_shortlist_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_connection_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';

class TalentScoutDashboardScreen extends ConsumerStatefulWidget {
  const TalentScoutDashboardScreen({super.key});

  @override
  ConsumerState<TalentScoutDashboardScreen> createState() => _TalentScoutDashboardScreenState();
}

class _TalentScoutDashboardScreenState extends ConsumerState<TalentScoutDashboardScreen> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(talentScoutProvider.notifier).loadProfile();
      ref.read(scoutShortlistProvider.notifier).load();
      ref.read(scoutConnectionProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('SportX',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, color: AppColors.textPrimary),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: _currentTabIndex == 0 ? _buildHomeTab() : const Center(child: Text('Under Construction')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            context.push('/scout-discovery');
          } else if (index == 2) {
            context.push('/scout-shortlist');
          } else if (index == 3) {
            context.push('/scout-connections');
          } else {
            setState(() => _currentTabIndex = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.home),
            selectedIcon: Icon(LucideIcons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.search),
            selectedIcon: Icon(LucideIcons.search, color: AppColors.primary),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.star),
            selectedIcon: Icon(LucideIcons.star, color: AppColors.primary),
            label: 'Shortlist',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.user),
            selectedIcon: Icon(LucideIcons.user, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Profile completeness: 6 fields - sportsSpecialization mandatory + 5 optional weighted
  double _completeness() {
    final p = ref.watch(talentScoutProvider).profile;
    if (p == null) return 0;
    int filled = 0;
    const total = 6;
    if (p.sportsSpecialization.isNotEmpty) filled++;
    if ((p.organization ?? '').isNotEmpty) filled++;
    if ((p.affiliation ?? '').isNotEmpty) filled++;
    if (p.experienceYears != null) filled++;
    if (p.cityId != null) filled++;
    if ((p.bio ?? '').isNotEmpty) filled++;
    return filled / total;
  }

  Widget _buildHomeTab() {
    final shortlistState = ref.watch(scoutShortlistProvider);
    final shortlist = shortlistState.items;
    final connectionState = ref.watch(scoutConnectionProvider);
    final connectionStats = connectionState.stats;
    final profileState = ref.watch(talentScoutProvider);
    if ((shortlistState.isLoading && shortlist.isEmpty) ||
        (connectionState.isLoading && connectionState.connections.isEmpty) ||
        profileState.isLoading) {
      return const SponsorDashboardSkeleton();
    }
    final user = ref.watch(authProvider).user;
    final profile = profileState.profile;
    final completeness = _completeness();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner — personalized
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.userSearch, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, ${user?.name ?? profile?.organization ?? 'Scout'}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      const Text('Discover and connect with athletes',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Profile completeness meter per spec FR-TS-2 / coach completeness pattern
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Profile completeness', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('${(completeness * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: completeness, minHeight: 6, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
              ),
              if (completeness < 1) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => context.push('/scout-profile'),
                  child: const Text('Complete your profile →', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(child: _buildStatCard('${shortlist.length}', 'Shortlisted')),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('${connectionStats.acceptedCount}', 'Connections')),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('${connectionStats.pendingCount}', 'Pending')),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Actions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAction(LucideIcons.search, 'Discover', () => context.push('/scout-discovery')),
                    _buildQuickAction(LucideIcons.star, 'Shortlist', () => context.push('/scout-shortlist')),
                    _buildQuickAction(LucideIcons.users, 'Connections', () => context.push('/scout-connections')),
                    _buildQuickAction(LucideIcons.user, 'Profile', () => context.push('/scout-profile')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recent Shortlist
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Shortlist',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () => context.push('/scout-shortlist'),
                      child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (shortlist.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No athletes shortlisted yet.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  )
                else
                  ...shortlist.take(3).map((s) => _buildAthleteItem(
                        s.athlete.fullName,
                        s.athlete.sports.isNotEmpty ? s.athlete.sports.first : 'N/A',
                        photoUrl: s.athlete.photoUrl,
                      )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(LucideIcons.logOut, size: 18),
            label: const Text('Log out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAthleteItem(String name, String sport, {String? photoUrl}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          AthleteAvatar(photoUrl: photoUrl, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(sport, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
