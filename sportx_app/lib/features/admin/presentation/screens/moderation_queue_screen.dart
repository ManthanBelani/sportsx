import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';

class ModerationQueueScreen extends ConsumerStatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  ConsumerState<ModerationQueueScreen> createState() =>
      _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends ConsumerState<ModerationQueueScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(adminProvider.notifier).loadReports();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return AdminWebLayout(
      title: 'Moderation Queue',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(adminProvider.notifier).loadReports();
          },
        ),
      ],
      child: adminState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildModerationList(adminState),
    );
  }

  Widget _buildModerationList(AdminState adminState) {
    final reports = adminState.reports;

    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              'No items in moderation queue',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All reports have been reviewed',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    final pendingReports = reports.where((r) => r.status == 'pending').toList();
    final reviewedReports = reports.where((r) => r.status != 'pending').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pendingReports.isNotEmpty) ...[
          AdminSectionLabel(
            label: 'Pending Review',
            count: pendingReports.length,
          ),
          const SizedBox(height: 12),
          ...pendingReports.map((report) => _buildReportItem(report, true)),
          const SizedBox(height: 24),
        ],
        if (reviewedReports.isNotEmpty) ...[
          AdminSectionLabel(
            label: 'Recently Reviewed',
            count: reviewedReports.length,
          ),
          const SizedBox(height: 12),
          ...reviewedReports.take(10).map((report) => _buildReportItem(report, false)),
        ],
      ],
    );
  }

  Widget _buildReportItem(Report report, bool isPending) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push(
          '/admin/reports/${report.id}',
          extra: report,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getContentTypeIcon(report.contentType),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.contentType.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          report.reason,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPending
                          ? AppColors.warning.withOpacity(0.1)
                          : AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isPending ? 'PENDING' : 'REVIEWED',
                      style: TextStyle(
                        color: isPending ? AppColors.warning : AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (report.contentPreview != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.contentPreview!,
                    style: TextStyle(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Reported by ${report.reportedByName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    report.createdAt,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleDismiss(report.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: const Text('Dismiss'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.push(
                          '/admin/reports/${report.id}',
                          extra: report,
                        ),
                        child: const Text('Review'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _getContentTypeIcon(String contentType) {
    IconData icon;
    Color color;

    switch (contentType) {
      case 'post':
        icon = Icons.article_outlined;
        color = AppColors.primary;
        break;
      case 'comment':
        icon = Icons.comment_outlined;
        color = AppColors.cta;
        break;
      case 'profile':
        icon = Icons.person_outlined;
        color = AppColors.info;
        break;
      default:
        icon = Icons.report_outlined;
        color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Future<void> _handleDismiss(String reportId) async {
    await ref.read(adminProvider.notifier).dismissReport(reportId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report dismissed')),
      );
    }
  }
}
