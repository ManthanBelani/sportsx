import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/date_format_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/sponsor/presentation/providers/sponsor_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class SponsorDashboardScreen extends ConsumerStatefulWidget {
  const SponsorDashboardScreen({super.key});

  @override
  ConsumerState<SponsorDashboardScreen> createState() => _SponsorDashboardScreenState();
}

class _SponsorDashboardScreenState extends ConsumerState<SponsorDashboardScreen> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(mySponsorshipsProvider.notifier).refresh();
      ref.read(shortlistProvider.notifier).load();
      ref.read(myApplicationsProvider);
    });
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
      body: _currentTabIndex == 0 ? _buildHomeTab() : const Center(child: Text('Under Construction')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            context.push('/my-sponsorships');
          } else if (index == 2) {
            context.push('/applications-inbox');
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
            icon: Icon(LucideIcons.clipboardList),
            selectedIcon: Icon(LucideIcons.clipboardList, color: AppColors.primary),
            label: 'Listings',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.inbox),
            selectedIcon: Icon(LucideIcons.inbox, color: AppColors.primary),
            label: 'Inbox',
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

  Widget _buildHomeTab() {
    final sponsorshipsState = ref.watch(mySponsorshipsProvider);
    final listings = sponsorshipsState.items;
    final shortlistState = ref.watch(shortlistProvider);
    final shortlist = shortlistState.items;
    final applicationsAsync = ref.watch(myApplicationsProvider);
    final applications = applicationsAsync.valueOrNull ?? [];
    if ((sponsorshipsState.isLoading && listings.isEmpty) ||
        (shortlistState.isLoading && shortlist.isEmpty) ||
        applicationsAsync.isLoading) {
      return const SponsorDashboardSkeleton();
    }
    final active = listings.where((s) => s.status == 'published').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Banner (v2 .greet)
          GreetCard(
            title: 'Sponsor Dashboard',
            subtitle: 'Manage your sponsorships & applications',
            progress: listings.isEmpty ? 0 : active / listings.length,
            avatarText: 'S',
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(child: _buildStatCard('$active', 'Active Listings')),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('${applications.length}', 'Applications')),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('${shortlist.length}', 'Shortlisted')),
            ],
          ),
          const SizedBox(height: 16),

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
              QuickTile(label: 'New Listing', icon: LucideIcons.plusCircle, tintBg: AppColors.yellowTint, tintFg: AppColors.warnText, onTap: () => context.push('/sponsor-posting')),
              QuickTile(label: 'Applications', icon: LucideIcons.inbox, tintBg: AppColors.infoLight, tintFg: AppColors.info, onTap: () => context.push('/applications-inbox')),
              QuickTile(label: 'Discover', icon: LucideIcons.search, tintBg: AppColors.successLight, tintFg: const Color(0xFF15803D), onTap: () => context.push('/athlete-discovery')),
              QuickTile(label: 'Shortlist', icon: LucideIcons.star, tintBg: const Color(0xFFF1F3F5), tintFg: AppColors.dark, onTap: () => context.push('/shortlist')),
            ],
          ),
          const SizedBox(height: 16),

          // My Sponsorships
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: SportXShadows.e1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'My Sponsorships', actionText: 'View All', onActionTap: () => context.push('/my-sponsorships')),
                const SizedBox(height: 12),
                if (listings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No sponsorships yet.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  )
                else
                  ...listings.take(3).map((s) => _buildListingItem(
                        s.title,
                        [s.sport?.name, s.sponsorshipType].whereType<String>().join(' · '),
                        s.status[0].toUpperCase() + s.status.substring(1),
                      )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recent Applications
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: SportXShadows.e1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Recent Applications', actionText: 'View All', onActionTap: () => context.push('/applications-inbox')),
                const SizedBox(height: 12),
                if (applications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No applications yet.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  )
                else
                      ...applications.take(3).map((a) {
                        final raw = a['created_at']?.toString();
                        final formatted = raw != null && raw.isNotEmpty ? DateFormatUtils.formatRelative(raw) : '';
                        final sport = a['sport']?.toString() ?? '';
                        final meta = [sport, formatted].where((s) => s.isNotEmpty).join(' • ');
                        return _buildApplicationItem(
                          (a['athlete_name'] ?? a['name'] ?? 'Athlete').toString(),
                          meta.isEmpty ? sport : meta,
                        );
                      }),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: SportXShadows.e1,
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildListingItem(String title, String meta, String status) {
    final PillKind kind;
    if (status == 'Active' || status == 'Published') {
      kind = PillKind.ok;
    } else if (status == 'Draft') {
      kind = PillKind.draft;
    } else {
      kind = PillKind.pending;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(meta, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          StatusPill(label: status, kind: kind),
        ],
      ),
    );
  }

  Widget _buildApplicationItem(String name, String meta) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Icon(LucideIcons.user, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(meta, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
