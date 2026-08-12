import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/theme/colors.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Admin Dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
              Expanded(child: _buildStatCard(context, 'Active Listings', '${stats?.activeListings ?? '—'}', Icons.list_alt, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, 'Flagged Items', '${stats?.flaggedItems ?? '—'}', Icons.flag, Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(context, 'Pending Expirations', '${stats?.pendingExpirations ?? '—'}', Icons.timer, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, 'New Signups', '${stats?.newSignups30d ?? '—'}', Icons.person_add, Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(context, 'Total Users', '${stats?.totalUsers ?? '—'}', Icons.group, AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, 'Pending Approvals', '${stats?.pendingApprovals ?? '—'}', Icons.pending_actions, AppColors.warning)),
            ],
          ),
          const SizedBox(height: 32),
          Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildActionCard(context, 'Reports', Icons.bar_chart, () => context.push('/admin/reports'))),
              const SizedBox(width: 12),
              Expanded(child: _buildActionCard(context, 'Users', Icons.people, () => context.push('/admin/users'))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionCard(context, 'Moderation', Icons.shield, () => context.push('/admin/moderation'))),
              const SizedBox(width: 12),
              Expanded(child: _buildActionCard(context, 'Approvals', Icons.verified, () => context.push('/admin/approvals'))),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
