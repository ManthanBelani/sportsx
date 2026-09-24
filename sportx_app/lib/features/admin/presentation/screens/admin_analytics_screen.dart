import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// v2 admin-analytics.html — platform analytics dashboard.
/// Read-only view over adminProvider.stats (loadDashboard) plus the
/// already-loaded users/reports/opportunities lists.
class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(adminProvider.notifier).loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final stats = state.stats;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.ink),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/admin/dashboard'),
        ),
        title: Text('Analytics',
            style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      ),
      body: RefreshIndicator(
        color: AppColors.yellowDeep,
        onRefresh: () => ref.read(adminProvider.notifier).loadDashboard(),
        child: state.isLoading && stats == null
            ? const GenericListSkeleton()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.25,
                    children: [
                      _stat('Total Users', '${stats?.totalUsers ?? 0}',
                          LucideIcons.users, AppColors.infoLight, AppColors.info),
                      _stat('Active Listings',
                          '${stats?.activeListings ?? 0}', LucideIcons.layers,
                          AppColors.yellowTint, AppColors.warnText),
                      _stat('New Signups · 30d',
                          '${stats?.newSignups30d ?? 0}', LucideIcons.userPlus,
                          const Color(0xFFDCFCE7), const Color(0xFF15803D)),
                      _stat('Flagged Items',
                          '${stats?.flaggedItems ?? 0}', LucideIcons.flag,
                          const Color(0xFFFEE2E2), AppColors.error),
                      _stat('Pending Approvals',
                          '${stats?.pendingApprovals ?? 0}', LucideIcons.hourglass,
                          AppColors.yellowTint, AppColors.warnText),
                      _stat('Reports Today',
                          '${stats?.reportsToday ?? 0}', LucideIcons.shieldAlert,
                          const Color(0xFFFEE2E2), AppColors.error),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(title: 'Users by Role'),
                  _distCard(stats?.usersByRole ?? const {}),
                  const SizedBox(height: 18),
                  const SectionHeader(title: 'Users by Region'),
                  _distCard(stats?.usersByRegion ?? const {},
                      emptyHint: 'No regional data yet'),
                  const SizedBox(height: 18),
                  const SectionHeader(title: 'Users by Sport'),
                  _distCard(stats?.usersBySport ?? const {},
                      emptyHint: 'No sport data yet'),
                ],
              ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color tintBg,
      Color tintFg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: SportXShadows.e1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: tintBg),
            alignment: Alignment.center,
            child: Icon(icon, size: 15, color: tintFg),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: GoogleFonts.sora(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
            ),
          ),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _distCard(Map<String, int> data, {String? emptyHint}) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        child: Text(emptyHint ?? 'No data yet',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary)),
      );
    }
    final total = data.values.fold<int>(0, (a, b) => a + b);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
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
          for (final e in entries.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(e.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                      ),
                      Text('${e.value}',
                          style: GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : e.value / total,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEDEFF2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFF5B400)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
