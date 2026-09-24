import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class AcademyDashboardScreen extends ConsumerStatefulWidget {
  const AcademyDashboardScreen({super.key});

  @override
  ConsumerState<AcademyDashboardScreen> createState() => _AcademyDashboardScreenState();
}

class _AcademyDashboardScreenState extends ConsumerState<AcademyDashboardScreen> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(myAcademyProvider);
      ref.read(myTrialsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('SportX',
            style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
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
            context.push('/my-trials');
          } else if (index == 2) {
            context.push('/enquiry-inbox');
          } else if (index == 3) {
            context.push('/academy-profile');
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
            label: 'Trials',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.messageCircle),
            selectedIcon: Icon(LucideIcons.messageCircle, color: AppColors.primary),
            label: 'Enquiries',
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
    final academyAsync = ref.watch(myAcademyProvider);
    final academy = academyAsync.valueOrNull;
    final trialsState = ref.watch(myTrialsProvider);
    final trials = trialsState.items;
    if (academyAsync.isLoading || (trialsState.isLoading && trials.isEmpty)) {
      return const SponsorDashboardSkeleton();
    }
    final active = trials.where((t) => t.status == 'published').length;
    final drafts = trials.where((t) => t.status == 'draft').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Academy Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: SportXShadows.e1,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.academy,
                    borderRadius: BorderRadius.circular(16),
                    image: academy?.logoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(academy!.logoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: academy?.logoUrl == null
                      ? const Icon(LucideIcons.building2, color: Colors.white, size: 28)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(academy?.name ?? 'My Academy',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        [academy?.sport?.name, academy?.city?.name].whereType<String>().where((s) => s.isNotEmpty).join(' • '),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
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
              Expanded(child: _buildStatCard('$active', 'Active Trials')),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('${trials.length}', 'Total Trials')),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('$drafts', 'Drafts')),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: SportXShadows.e1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Quick Actions'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAction(LucideIcons.plusCircle, 'Post Trial', () => context.push('/post-trial')),
                    _buildQuickAction(LucideIcons.clipboardList, 'My Trials', () => context.push('/my-trials')),
                    _buildQuickAction(LucideIcons.messageCircle, 'Enquiries', () => context.push('/enquiry-inbox')),
                    _buildQuickAction(LucideIcons.user, 'Edit Listing', () => context.push('/edit-academy-profile')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // My Trials List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: SportXShadows.e1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                    title: 'My Trials', actionText: 'View All', onActionTap: () => context.push('/my-trials')),
                if (trials.isEmpty)
                   Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No trials yet. Tap “Post Trial” to create one.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                  )
                else
                  ...trials.take(3).map((t) {
                    final dateStr = t.trialDate != null
                        ? '${t.trialDate!.day}/${t.trialDate!.month}/${t.trialDate!.year} • ${t.filledSpots ?? 0} registrations'
                        : '${t.filledSpots ?? 0} registrations';
                    final status = t.status[0].toUpperCase() + t.status.substring(1);
                    return _buildTrialItem(t.title, dateStr, status, LucideIcons.circleDot);
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: AppColors.academy),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTrialItem(String title, String meta, String status, IconData icon) {
    final PillKind pillKind =
        status == 'Published' ? PillKind.ok : status == 'Draft' ? PillKind.pending : PillKind.draft;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: AppColors.academy),
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
          StatusPill(label: status, kind: pillKind),
        ],
      ),
    );
  }
}
