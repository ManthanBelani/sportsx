import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(adminProvider).stats;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text('Admin Dashboard',
            style: GoogleFonts.sora(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: AppColors.ink),
            onPressed: () {
              ref.read(adminProvider.notifier).logout();
              context.go('/admin/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(context, 'Active Listings', '${stats?.activeListings ?? '—'}', LucideIcons.list, AppColors.info)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, 'Flagged Items', '${stats?.flaggedItems ?? '—'}', LucideIcons.flag, AppColors.admin)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(context, 'Pending Expirations', '${stats?.pendingExpirations ?? '—'}', LucideIcons.timer, AppColors.organizer)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, 'New Signups', '${stats?.newSignups30d ?? '—'}', LucideIcons.userPlus, AppColors.academy)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(context, 'Total Users', '${stats?.totalUsers ?? '—'}', LucideIcons.users, AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, 'Pending Approvals', '${stats?.pendingApprovals ?? '—'}', LucideIcons.clock, AppColors.warning)),
            ],
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Quick Actions'),
          Row(
            children: [
              Expanded(child: _buildActionCard(context, 'Reports', LucideIcons.chartColumn, AppColors.errorLight, AppColors.admin, () => context.push('/admin/reports'))),
              const SizedBox(width: 12),
              Expanded(child: _buildActionCard(context, 'Users', LucideIcons.users, AppColors.yellowTint, AppColors.primaryDark, () => context.push('/admin/users'))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionCard(context, 'Moderation', LucideIcons.shield, AppColors.errorLight, AppColors.admin, () => context.push('/admin/moderation'))),
              const SizedBox(width: 12),
              Expanded(child: _buildActionCard(context, 'Approvals', LucideIcons.badgeCheck, AppColors.successLight, AppColors.academy, () => context.push('/admin/approvals'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.sora(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(title,
              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon,
      Color tintBg, Color tintFg, VoidCallback onTap) {
    return QuickTile(label: title, icon: icon, tintBg: tintBg, tintFg: tintFg, onTap: onTap);
  }
}
