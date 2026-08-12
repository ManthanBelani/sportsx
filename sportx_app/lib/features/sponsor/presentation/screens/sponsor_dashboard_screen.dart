import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/sponsor/presentation/providers/sponsor_provider.dart';
import 'package:sportx_app/theme/colors.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('SportX', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
        onDestinationSelected: (index) => setState(() => _currentTabIndex = index),
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
    final listings = ref.watch(mySponsorshipsProvider).items;
    final shortlist = ref.watch(shortlistProvider).items;
    final applications = ref.watch(myApplicationsProvider).valueOrNull ?? [];
    final active = listings.where((s) => s.status == 'published').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Banner
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
                  child: const Icon(LucideIcons.award, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sponsor Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      SizedBox(height: 2),
                      Text('Manage your sponsorships & applications', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
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
                const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAction(LucideIcons.plusCircle, 'New Listing', () => context.push('/sponsor-posting')),
                    _buildQuickAction(LucideIcons.inbox, 'Applications', () => context.push('/applications-inbox')),
                    _buildQuickAction(LucideIcons.search, 'Discover', () => context.push('/athlete-discovery')),
                    _buildQuickAction(LucideIcons.star, 'Shortlist', () => context.push('/shortlist')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // My Sponsorships
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
                    const Text('My Sponsorships', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () => context.push('/my-sponsorships'),
                      child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                    ),
                  ],
                ),
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Applications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () => context.push('/applications-inbox'),
                      child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (applications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No applications yet.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  )
                else
                  ...applications.take(3).map((a) => _buildApplicationItem(
                        (a['athlete_name'] ?? a['name'] ?? 'Athlete').toString(),
                        '${a['sport'] ?? ''} • ${a['created_at'] ?? ''}',
                      )),
              ],
            ),
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
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
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

  Widget _buildListingItem(String title, String meta, String status) {
    Color badgeColor;
    Color badgeText;
    if (status == 'Active') {
      badgeColor = const Color(0xFFd1fae5);
      badgeText = const Color(0xFF065f46);
    } else {
      badgeColor = AppColors.surface;
      badgeText = AppColors.textSecondary;
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)),
            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeText)),
          ),
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
