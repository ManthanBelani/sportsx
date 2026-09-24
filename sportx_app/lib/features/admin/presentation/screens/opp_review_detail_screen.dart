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

class OppReviewDetailScreen extends ConsumerStatefulWidget {
  final Opportunity opportunity;

  const OppReviewDetailScreen({super.key, required this.opportunity});

  @override
  ConsumerState<OppReviewDetailScreen> createState() =>
      _OppReviewDetailScreenState();
}

class _OppReviewDetailScreenState extends ConsumerState<OppReviewDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final opportunity = widget.opportunity;

    return AdminWebLayout(
      title: 'Opportunity Review',
      actions: [
        if (opportunity.status == 'pending')
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'approve',
                child: Text('Approve'),
              ),
              const PopupMenuItem(
                value: 'reject',
                child: Text('Reject'),
              ),
            ],
          ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(opportunity),
            const SizedBox(height: 24),
            _buildOpportunityDetails(opportunity),
            const SizedBox(height: 24),
            _buildSponsorInfo(opportunity),
            const SizedBox(height: 24),
            _buildBudgetInfo(opportunity),
            const SizedBox(height: 24),
            if (opportunity.status == 'pending') _buildActionButtons(opportunity),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Opportunity opportunity) {
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
                  label: opportunity.status.toUpperCase(),
                  kind: opportunity.status == 'approved'
                      ? PillKind.ok
                      : opportunity.status == 'rejected'
                          ? PillKind.no
                          : PillKind.pending,
                ),
                const Spacer(),
                Text(
                  'Posted: ${opportunity.createdAt}',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              opportunity.title,
              style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpportunityDetails(Opportunity opportunity) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Opportunity Details'),
            const SizedBox(height: 16),
            if (opportunity.description != null) ...[
              Text(
                'Description:',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(opportunity.description!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSponsorInfo(Opportunity opportunity) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Sponsor Information'),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.yellowTint,
                child: opportunity.sponsorLogo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          opportunity.sponsorLogo!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(LucideIcons.building2, color: AppColors.ink),
              ),
              title: Text(
                opportunity.sponsorName,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetInfo(Opportunity opportunity) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Budget & Compensation'),
            const SizedBox(height: 16),
            if (opportunity.budget != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.ctaLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.indianRupee, color: AppColors.ctaDark),
                    const SizedBox(width: 8),
                    Text(
                      opportunity.budget!,
                      style: GoogleFonts.inter(
                        color: AppColors.ctaDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'Budget not specified',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Opportunity opportunity) {
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
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                      label: 'Reject', onPressed: () => _handleApproval('reject')),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                      label: 'Approve',
                      icon: LucideIcons.check,
                      onPressed: () => _handleApproval('approve')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApproval(String action) async {
    final notifier = ref.read(adminProvider.notifier);
    bool success;

    if (action == 'approve') {
      success = await notifier.approveOpportunity(widget.opportunity.id);
    } else {
      success = await notifier.rejectOpportunity(widget.opportunity.id);
    }

    if (success && mounted) {
      SnackBarUtils.showSuccess(context, action == 'approve'
                ? 'Opportunity approved'
                : 'Opportunity rejected',);
      context.pop();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'approve':
        _handleApproval('approve');
        break;
      case 'reject':
        _handleApproval('reject');
        break;
    }
  }
}
