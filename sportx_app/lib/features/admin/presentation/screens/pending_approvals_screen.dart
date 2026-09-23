import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

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
          icon: const Icon(LucideIcons.refreshCw),
          onPressed: () {
            ref.read(adminProvider.notifier).loadPendingApprovals();
          },
        ),
      ],
      child: adminState.isLoading
          ? const GenericListSkeleton()
          : adminState.pendingApprovals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.circleCheck, size: 64, color: AppColors.success),
                      const SizedBox(height: 16),
                      Text(
                        'No pending approvals',
                        style: GoogleFonts.sora(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: SportXShadows.e1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFE9A8), Color(0xFFFFC107), Color(0xFFF5B400)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    role == 'coach'
                        ? LucideIcons.dumbbell
                        : role == 'sponsor'
                            ? LucideIcons.building2
                            : LucideIcons.graduationCap,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.sora(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        email,
                        style: GoogleFonts.inter(color: AppColors.textSecondary),
                      ),
                      if (city != null)
                        Text(
                          city,
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                StatusPill(label: role.toUpperCase(), kind: PillKind.pending),
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
                  child: SecondaryButton(label: 'Reject', onPressed: onReject),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                      label: 'Approve', icon: LucideIcons.check, onPressed: onApprove),
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
      SnackBarUtils.showSuccess(context, action == 'approve' ? 'Application approved' : 'Application rejected',);
    }
  }
}