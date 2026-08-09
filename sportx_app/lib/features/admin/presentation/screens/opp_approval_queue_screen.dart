import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';

class OppApprovalQueueScreen extends ConsumerStatefulWidget {
  const OppApprovalQueueScreen({super.key});

  @override
  ConsumerState<OppApprovalQueueScreen> createState() =>
      _OppApprovalQueueScreenState();
}

class _OppApprovalQueueScreenState extends ConsumerState<OppApprovalQueueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    ref.read(adminProvider.notifier).loadOpportunities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return AdminWebLayout(
      title: 'Opportunity Approval Queue',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(adminProvider.notifier).loadOpportunities();
          },
        ),
      ],
      child: Column(
        children: [
          AdminTabPills(
            tabs: ['Pending', 'Approved', 'Rejected'],
            selectedIndex: _tabController.index,
            onTabChanged: (index) {
              setState(() {
                _tabController.animateTo(index);
              });
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOpportunityList(adminState, 'pending'),
                _buildOpportunityList(adminState, 'approved'),
                _buildOpportunityList(adminState, 'rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityList(AdminState adminState, String status) {
    if (adminState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final opportunities = adminState.opportunities
        .where((opp) => opp.status == status)
        .toList();

    if (opportunities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'pending'
                  ? Icons.pending_actions
                  : status == 'approved'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No $status opportunities',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: opportunities.length,
      itemBuilder: (context, index) {
        final opportunity = opportunities[index];
        return AdminOpportunityCard(
          title: opportunity.title,
          sponsorName: opportunity.sponsorName,
          budget: opportunity.budget,
          status: opportunity.status,
          time: opportunity.createdAt,
          onTap: () => context.push(
            '/admin/opportunities/${opportunity.id}',
            extra: opportunity,
          ),
          onApprove: status == 'pending'
              ? () => _handleApproval(opportunity.id, 'approve')
              : null,
          onReject: status == 'pending'
              ? () => _handleApproval(opportunity.id, 'reject')
              : null,
        );
      },
    );
  }

  Future<void> _handleApproval(String oppId, String action) async {
    final notifier = ref.read(adminProvider.notifier);
    bool success;

    if (action == 'approve') {
      success = await notifier.approveOpportunity(oppId);
    } else {
      success = await notifier.rejectOpportunity(oppId);
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
    }
  }
}
