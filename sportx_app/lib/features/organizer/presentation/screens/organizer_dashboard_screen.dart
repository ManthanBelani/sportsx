import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class OrganizerDashboardScreen extends ConsumerStatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  ConsumerState<OrganizerDashboardScreen> createState() => _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends ConsumerState<OrganizerDashboardScreen> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(myTrialsProvider.notifier).refresh();
      ref.read(myTournamentsProvider.notifier).refresh();
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
            icon: Icon(LucideIcons.calendar),
            selectedIcon: Icon(LucideIcons.calendar, color: AppColors.primary),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.barChart2),
            selectedIcon: Icon(LucideIcons.barChart2, color: AppColors.primary),
            label: 'Stats',
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
    final trials = ref.watch(myTrialsProvider).items;
    final tournaments = ref.watch(myTournamentsProvider).items;
    final activeTrials = trials.where((t) => t.status == 'published').length;
    final activeTournaments = tournaments.where((t) => t.status == 'published').length;
    final totalRegs = trials.fold<int>(0, (s, t) => s + (t.filledSpots ?? 0)) +
        tournaments.fold<int>(0, (s, t) => s + (t.filledSpots ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            children: [
              Expanded(child: _buildStatCard('$activeTrials', 'Active Trials')),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('$activeTournaments', 'Tournaments')),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('$totalRegs', 'Registrations')),
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
                    _buildQuickAction(LucideIcons.clipboardList, 'Post Trial', () => context.push('/post-trial')),
                    _buildQuickAction(LucideIcons.trophy, 'Post Tournament', () => context.push('/post-tournament')),
                    _buildQuickAction(LucideIcons.barChart2, 'My Tournaments', () => context.push('/my-tournaments')),
                    _buildQuickAction(LucideIcons.list, 'My Trials', () => context.push('/my-trials')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // My Trials
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
                    const Text('My Trials', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () => context.push('/my-trials'),
                      child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (trials.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No trials yet.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  )
                else
                  ...trials.take(3).map((t) => _buildEventItem(
                        t.title,
                        t.trialDate != null
                            ? '${t.trialDate!.day}/${t.trialDate!.month}/${t.trialDate!.year} • ${t.filledSpots ?? 0} registrations'
                            : '${t.filledSpots ?? 0} registrations',
                        t.status[0].toUpperCase() + t.status.substring(1),
                        LucideIcons.circleDot,
                      )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // My Tournaments
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
                    const Text('My Tournaments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () => context.push('/my-tournaments'),
                      child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (tournaments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No tournaments yet.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  )
                else
                  ...tournaments.take(3).map((t) => _buildEventItem(
                        t.title,
                        t.startDate != null && t.endDate != null
                            ? '${t.startDate!.day}/${t.startDate!.month}–${t.endDate!.day}/${t.endDate!.month}/${t.endDate!.year} • ${t.filledSpots ?? 0} registered'
                            : '${t.filledSpots ?? 0} registered',
                        t.status[0].toUpperCase() + t.status.substring(1),
                        LucideIcons.trophy,
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

  Widget _buildEventItem(String title, String meta, String status, IconData icon) {
    Color badgeColor;
    Color badgeText;
    if (status == 'Active' || status == 'Published') {
      badgeColor = const Color(0xFFd1fae5);
      badgeText = const Color(0xFF065f46);
    } else if (status == 'Draft') {
      badgeColor = const Color(0xFFfef3c7);
      badgeText = const Color(0xFF92400e);
    } else {
      badgeColor = AppColors.surface;
      badgeText = AppColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
}
