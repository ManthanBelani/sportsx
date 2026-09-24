import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

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
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusPill(
                  label: isPending ? 'PENDING' : 'REVIEWED',
                  kind: isPending ? PillKind.pending : PillKind.ok,
                ),
                const SizedBox(width: 12),
                Text(
                  'Report #${report.id}',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  report.createdAt,
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Reason: ${report.reason}',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (report.description != null) ...[
              const SizedBox(height: 8),
              Text(
                report.description!,
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentPreview(Report report) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
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
                borderRadius: BorderRadius.circular(10),
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
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    report.contentPreview ?? 'No content preview available',
                    style: GoogleFonts.inter(fontSize: 14),
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
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
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
                child: Icon(LucideIcons.user, color: AppColors.info),
              ),
              title: Text(
                report.reportedByName,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
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
                child: PrimaryButton(
                    label: 'Mark as Resolved',
                    icon: LucideIcons.circleCheck,
                    onPressed: () => _handleResolve()),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                    label: 'Dismiss Report', onPressed: () => _handleDismiss()),
              ),
            ] else
              Text(
                'This report has been ${report.status}',
                style: GoogleFonts.inter(
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
        return LucideIcons.fileText;
      case 'comment':
        return LucideIcons.messageCircle;
      case 'profile':
        return LucideIcons.user;
      default:
        return LucideIcons.flag;
    }
  }

  Future<void> _handleResolve() async {
    await ref.read(adminProvider.notifier).approveReport(widget.report.id);
    if (mounted) {
      SnackBarUtils.showSuccess(context, 'Report marked as resolved');
      context.pop();
    }
  }

  Future<void> _handleDismiss() async {
    await ref.read(adminProvider.notifier).dismissReport(widget.report.id);
    if (mounted) {
      SnackBarUtils.showSuccess(context, 'Report dismissed');
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
