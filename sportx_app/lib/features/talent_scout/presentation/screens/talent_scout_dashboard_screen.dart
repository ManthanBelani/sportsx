import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class TalentScoutDashboardScreen extends ConsumerStatefulWidget {
  const TalentScoutDashboardScreen({super.key});

  @override
  ConsumerState<TalentScoutDashboardScreen> createState() => _TalentScoutDashboardScreenState();
}

class _TalentScoutDashboardScreenState extends ConsumerState<TalentScoutDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(talentScoutProvider.notifier).loadProfile();
      ref.read(scoutShortlistProvider.notifier).load();
      ref.read(scoutConnectionProvider.notifier).load();
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(talentScoutProvider.notifier).loadProfile(),
      ref.read(scoutShortlistProvider.notifier).load(),
      ref.read(scoutConnectionProvider.notifier).load(),
    ]);
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SportXTopBar(
        titleWidget: Text('SportX',
            style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SportXIconButton(
              icon: LucideIcons.bell,
              onTap: () => context.push('/notifications'),
            ),
          ),
        ],
      ),
      body: _buildHomeTab(),
    );
  }

  Widget _buildHomeTab() {
    final shortlistState = ref.watch(scoutShortlistProvider);
    final shortlist = shortlistState.items;
    final connectionState = ref.watch(scoutConnectionProvider);
    final connectionStats = connectionState.stats;
    final profileState = ref.watch(talentScoutProvider);
    final hasError = profileState.error != null || shortlistState.error != null || connectionState.error != null;

    if ((shortlistState.isLoading && shortlist.isEmpty) ||
        (connectionState.isLoading && connectionState.connections.isEmpty) ||
        profileState.isLoading) {
      return const SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child: ScoutDashboardSkeleton());
    }

    if (hasError && shortlist.isEmpty && connectionState.connections.isEmpty && profileState.profile == null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.border),
          const SizedBox(height: 12),
          Text(profileState.error ?? shortlistState.error ?? connectionState.error ?? 'Failed to load',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Retry', onPressed: _refreshAll),
        ]),
      );
    }

    final user = ref.watch(authProvider).user;
    final profile = profileState.profile;
    final completeness = _completeness();

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Welcome + completeness (v2 .greet)
          GreetCard(
            title: 'Welcome, ${user?.name ?? profile?.organization ?? 'Scout'}',
            subtitle: completeness < 1
                ? 'Complete your profile to build athlete trust'
                : 'Discover and connect with athletes',
            progress: completeness,
            avatarText: (user?.name ?? profile?.organization ?? 'S').isNotEmpty
                ? (user?.name ?? profile?.organization ?? 'S')[0].toUpperCase()
                : 'S',
          ),
          if (completeness < 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SecondaryButton(
                label: 'Complete your profile',
                icon: LucideIcons.arrowRight,
                onPressed: () => context.push('/scout-profile'),
              ),
            ),
          // Stats Row
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: SportXShadows.e1,
            ),
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Expanded(child: _buildStatCard('${shortlist.length}', 'Shortlisted')),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('${connectionStats.acceptedCount}', 'Connections')),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('${connectionStats.pendingCount}', 'Pending')),
            ]),
          ),
          _divider(),
          // Quick Actions (v2 .tiles)
          const SectionHeader(title: 'Quick Actions'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              QuickTile(label: 'Discover', icon: LucideIcons.search, tintBg: AppColors.infoLight, tintFg: AppColors.scout, onTap: () => context.push('/scout-discovery')),
              QuickTile(label: 'Shortlist', icon: LucideIcons.star, tintBg: AppColors.yellowTint, tintFg: AppColors.warnText, onTap: () => context.push('/scout-shortlist')),
              QuickTile(label: 'Connections', icon: LucideIcons.users, tintBg: AppColors.successLight, tintFg: const Color(0xFF15803D), onTap: () => context.push('/scout-connections')),
              QuickTile(label: 'Profile', icon: LucideIcons.user, tintBg: const Color(0xFFF1F3F5), tintFg: AppColors.dark, onTap: () => context.push('/scout-profile')),
            ],
          ),
          _divider(),
          // Recent Shortlist
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: SportXShadows.e1,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionHeader(title: 'Recent Shortlist', actionText: 'View All', onActionTap: () => context.push('/scout-shortlist')),
              if (shortlist.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.borderSoft), borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    const Icon(LucideIcons.star, size: 24, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    const Text('No athletes shortlisted yet.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    SecondaryButton(label: 'Discover Athletes', icon: LucideIcons.search, onPressed: () => context.push('/scout-discovery')),
                  ]),
                )
              else
                ...shortlist.take(3).map((s) => _buildAthleteItem(s.athlete.fullName, s.athlete.sports.isNotEmpty ? s.athlete.sports.first : 'N/A', photoUrl: s.athlete.photoUrl)),
            ]),
          ),
          _divider(),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: SportXShadows.e1,
            ),
            padding: const EdgeInsets.all(20),
            child: OutlinedButton.icon(
              onPressed: () async => await ref.read(authProvider.notifier).logout(),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: const Text('Log out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _divider() => const SizedBox(height: 12);

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16), boxShadow: SportXShadows.e1),
      child: Column(children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.scout)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildAthleteItem(String name, String sport, {String? photoUrl}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        AthleteAvatar(photoUrl: photoUrl, radius: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(sport, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
      ]),
    );
  }
}
