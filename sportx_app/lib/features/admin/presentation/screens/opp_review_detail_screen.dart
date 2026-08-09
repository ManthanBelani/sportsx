import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';

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
    final statusColor = _getStatusColor(opportunity.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    opportunity.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Posted: ${opportunity.createdAt}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              opportunity.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpportunityDetails(Opportunity opportunity) {
    return Card(
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
                style: TextStyle(
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
                  borderRadius: BorderRadius.circular(8),
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
                backgroundColor: AppColors.primaryLight,
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
                    : Icon(Icons.business, color: AppColors.primary),
              ),
              title: Text(
                opportunity.sponsorName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetInfo(Opportunity opportunity) {
    return Card(
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.currency_rupee, color: AppColors.ctaDark),
                    const SizedBox(width: 8),
                    Text(
                      opportunity.budget!,
                      style: TextStyle(
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
                style: TextStyle(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Opportunity opportunity) {
    return Card(
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
                  child: OutlinedButton.icon(
                    onPressed: () => _handleApproval('reject'),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApproval('approve'),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.warning;
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'approve'
                ? 'Opportunity approved'
                : 'Opportunity rejected',
          ),
        ),
      );
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
