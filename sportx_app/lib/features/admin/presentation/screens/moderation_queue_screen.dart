import 'package:flutter/material.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

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
          icon: const Icon(LucideIcons.refreshCw),
          onPressed: () {
            ref.read(adminProvider.notifier).loadReports();
          },
        ),
      ],
      child: adminState.isLoading
          ? const GenericListSkeleton()
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
            Icon(LucideIcons.circleCheck, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              'No items in moderation queue',
              style: GoogleFonts.sora(
                  fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              'All reports have been reviewed',
              style: GoogleFonts.inter(color: AppColors.textTertiary),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: SportXShadows.e1,
      ),
      child: InkWell(
        onTap: () => context.push(
          '/admin/reports/${report.id}',
          extra: report,
        ),
        borderRadius: BorderRadius.circular(16),
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
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          report.reason,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: isPending ? 'PENDING' : 'REVIEWED',
                    kind: isPending ? PillKind.pending : PillKind.ok,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (report.contentPreview != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.borderSoft),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    report.contentPreview!,
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(LucideIcons.user, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Reported by ${report.reportedByName}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    report.createdAt,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                          label: 'Dismiss',
                          onPressed: () => _handleDismiss(report.id)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Review',
                        onPressed: () => context.push(
                          '/admin/reports/${report.id}',
                          extra: report,
                        ),
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
        icon = LucideIcons.fileText;
        color = AppColors.primary;
        break;
      case 'comment':
        icon = LucideIcons.messageCircle;
        color = AppColors.cta;
        break;
      case 'profile':
        icon = LucideIcons.user;
        color = AppColors.info;
        break;
      default:
        icon = LucideIcons.flag;
        color = AppColors.admin;
    }

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Future<void> _handleDismiss(String reportId) async {
    await ref.read(adminProvider.notifier).dismissReport(reportId);
    if (mounted) {
      SnackBarUtils.showSuccess(context, 'Report dismissed');
    }
  }
}