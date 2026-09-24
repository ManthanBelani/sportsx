import 'package:flutter/material.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

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
          icon: const Icon(LucideIcons.refreshCw),
          onPressed: () {
            ref.read(adminProvider.notifier).loadPlatformStats();
          },
        ),
      ],
      child: adminState.isLoading
          ? const GenericListSkeleton()
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
          childAspectRatio: 1.3,
          children: [
            AdminStatCard(
              title: 'Total Users',
              value: '${stats?.totalUsers ?? 0}',
              icon: LucideIcons.users,
              color: AppColors.yellowDeep,
            ),
            AdminStatCard(
              title: 'Pending Approvals',
              value: '${stats?.pendingApprovals ?? 0}',
              icon: LucideIcons.clock,
              color: AppColors.warning,
            ),
            AdminStatCard(
              title: 'Reports Today',
              value: '${stats?.reportsToday ?? 0}',
              icon: LucideIcons.flag,
              color: AppColors.error,
            ),
            AdminStatCard(
              title: 'Active Sessions',
              value: '${stats?.activityMetrics['Active Sessions'] ?? 0}',
              icon: LucideIcons.trendingUp,
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
      AppColors.yellowDeep,
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
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
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
                          Text(role, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                          Text(
                            '$count (${percentage.toStringAsFixed(1)}%)',
                            style: GoogleFonts.inter(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(10),
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
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.inter(
                        color: AppColors.yellowDeep,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(entry.key),
                trailing: Text(
                  '${entry.value}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: stats.usersBySport.length,
            itemBuilder: (context, index) {
              final entry = stats.usersBySport.entries.elementAt(index);
              return ListTile(
                leading: Icon(
                  LucideIcons.trophy,
                  color: AppColors.yellowDeep,
                ),
                title: Text(entry.key),
                trailing: Text(
                  '${entry.value}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: SportXShadows.e1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.value.toString(),
                    style: GoogleFonts.sora(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.key,
                    style: GoogleFonts.inter(
                      fontSize: 12,
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