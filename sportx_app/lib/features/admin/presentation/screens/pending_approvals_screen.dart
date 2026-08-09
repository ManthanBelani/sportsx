import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';

class PendingApprovalsScreen extends ConsumerStatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  ConsumerState<PendingApprovalsScreen> createState() =>
      _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends ConsumerState<PendingApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(adminProvider.notifier).loadPendingApprovals();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return AdminWebLayout(
      title: 'Pending Approvals',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(adminProvider.notifier).loadPendingApprovals();
          },
        ),
      ],
      child: adminState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : adminState.pendingApprovals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                      const SizedBox(height: 16),
                      Text(
                        'No pending approvals',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: adminState.pendingApprovals.length,
                  itemBuilder: (context, index) {
                    final approval = adminState.pendingApprovals[index];
                    return _buildApprovalCard(
                      name: approval.name,
                      email: approval.email,
                      role: approval.role,
                      city: approval.city,
                      documents: approval.documents,
                      onApprove: () => _handleApproval(approval.id, 'approve'),
                      onReject: () => _handleApproval(approval.id, 'reject'),
                    );
                  },
                ),
    );
  }

  Widget _buildApprovalCard({
    required String name,
    required String email,
    required String role,
    String? city,
    List<String>? documents,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(
                    role == 'coach'
                        ? Icons.fitness_center
                        : role == 'sponsor'
                            ? Icons.business
                            : Icons.school,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      if (city != null)
                        Text(
                          city,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (documents != null && documents.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Documents:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: documents.map((doc) {
                  return Chip(
                    label: Text(doc),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.border),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  Future<void> _handleApproval(String userId, String action) async {
    final notifier = ref.read(adminProvider.notifier);

    if (action == 'approve') {
      await notifier.approveUser(userId);
    } else {
      await notifier.rejectUser(userId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'approve' ? 'Application approved' : 'Application rejected',
          ),
        ),
      );
    }
  }
}
