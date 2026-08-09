import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';

class PlatformReportsScreen extends ConsumerStatefulWidget {
  const PlatformReportsScreen({super.key});

  @override
  ConsumerState<PlatformReportsScreen> createState() => _PlatformReportsScreenState();
}

class _PlatformReportsScreenState extends ConsumerState<PlatformReportsScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(adminProvider.notifier).loadPlatformStats();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return AdminWebLayout(
      title: 'Platform Reports',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(adminProvider.notifier).loadPlatformStats();
          },
        ),
      ],
      child: adminState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(adminProvider.notifier).loadPlatformStats(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildQuickStats(adminState.stats),
                  const SizedBox(height: 24),
                  _buildUserBreakdown(adminState.stats),
                  const SizedBox(height: 24),
                  _buildUsersByRegion(adminState.stats),
                  const SizedBox(height: 24),
                  _buildUsersBySport(adminState.stats),
                  const SizedBox(height: 24),
                  _buildActivityMetrics(adminState.stats),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickStats(PlatformStats? stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionLabel(label: 'Quick Stats'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            AdminStatCard(
              title: 'Total Users',
              value: '${stats?.totalUsers ?? 0}',
              icon: Icons.people_outline,
              color: AppColors.primary,
            ),
            AdminStatCard(
              title: 'Pending Approvals',
              value: '${stats?.pendingApprovals ?? 0}',
              icon: Icons.pending_actions,
              color: AppColors.warning,
            ),
            AdminStatCard(
              title: 'Reports Today',
              value: '${stats?.reportsToday ?? 0}',
              icon: Icons.report_outlined,
              color: AppColors.error,
            ),
            AdminStatCard(
              title: 'Active Sessions',
              value: '${stats?.activityMetrics['Active Sessions'] ?? 0}',
              icon: Icons.trending_up,
              color: AppColors.success,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserBreakdown(PlatformStats? stats) {
    if (stats?.usersByRole == null || stats!.usersByRole.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = stats.usersByRole.values.fold(0, (sum, count) => sum + count);
    final colors = [
      AppColors.primary,
      AppColors.cta,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      AppColors.error,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionLabel(label: 'Users by Role'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: stats.usersByRole.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final role = entry.value.key;
                final count = entry.value.value;
                final percentage = total > 0 ? (count / total * 100) : 0.0;
                final color = colors[index % colors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(role, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            '$count (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersByRegion(PlatformStats? stats) {
    if (stats?.usersByRegion == null || stats!.usersByRegion.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionLabel(label: 'Users by Region'),
        const SizedBox(height: 12),
        Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: stats.usersByRegion.length,
            itemBuilder: (context, index) {
              final entry = stats.usersByRegion.entries.elementAt(index);
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(entry.key),
                trailing: Text(
                  '${entry.value}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersBySport(PlatformStats? stats) {
    if (stats?.usersBySport == null || stats!.usersBySport.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionLabel(label: 'Users by Sport'),
        const SizedBox(height: 12),
        Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: stats.usersBySport.length,
            itemBuilder: (context, index) {
              final entry = stats.usersBySport.entries.elementAt(index);
              return ListTile(
                leading: Icon(
                  Icons.sports,
                  color: AppColors.primary,
                ),
                title: Text(entry.key),
                trailing: Text(
                  '${entry.value}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityMetrics(PlatformStats? stats) {
    if (stats?.activityMetrics == null || stats!.activityMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionLabel(label: 'Activity Metrics (7-day)'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: stats.activityMetrics.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.value.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
