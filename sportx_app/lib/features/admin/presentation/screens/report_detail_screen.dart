import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return AdminWebLayout(
      title: 'Report Detail',
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'dismiss',
              child: Text('Dismiss Report'),
            ),
            const PopupMenuItem(
              value: 'resolve',
              child: Text('Mark as Resolved'),
            ),
          ],
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportHeader(report),
            const SizedBox(height: 24),
            _buildContentPreview(report),
            const SizedBox(height: 24),
            _buildReporterInfo(report),
            const SizedBox(height: 24),
            _buildActionPanel(report),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader(Report report) {
    final isPending = report.status == 'pending';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                const SizedBox(width: 12),
                Text(
                  'Report #${report.id}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  report.createdAt,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Reason: ${report.reason}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (report.description != null) ...[
              const SizedBox(height: 8),
              Text(
                report.description!,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentPreview(Report report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Reported Content'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIconForContentType(report.contentType),
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        report.contentType.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    report.contentPreview ?? 'No content preview available',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReporterInfo(Report report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Reporter'),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.infoLight,
                child: Icon(Icons.person, color: AppColors.info),
              ),
              title: Text(
                report.reportedByName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('User ID: ${report.reportedBy}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPanel(Report report) {
    final isPending = report.status == 'pending';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Actions'),
            const SizedBox(height: 16),
            if (isPending) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleResolve(),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Resolved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleDismiss(),
                  icon: const Icon(Icons.close),
                  label: const Text('Dismiss Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else
              Text(
                'This report has been ${report.status}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForContentType(String type) {
    switch (type) {
      case 'post':
        return Icons.article_outlined;
      case 'comment':
        return Icons.comment_outlined;
      case 'profile':
        return Icons.person_outlined;
      default:
        return Icons.report_outlined;
    }
  }

  Future<void> _handleResolve() async {
    await ref.read(adminProvider.notifier).approveReport(widget.report.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report marked as resolved')),
      );
      context.pop();
    }
  }

  Future<void> _handleDismiss() async {
    await ref.read(adminProvider.notifier).dismissReport(widget.report.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report dismissed')),
      );
      context.pop();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'dismiss':
        _handleDismiss();
        break;
      case 'resolve':
        _handleResolve();
        break;
    }
  }
}
