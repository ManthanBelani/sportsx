import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

/// Admin queue for blue-check verification requests
/// (docs/Verification-Badge-Implementation-Plan.md §4.2).
/// Approve flips the badge column on the profile; Reject requires a reason.
class VerificationQueueScreen extends ConsumerStatefulWidget {
  const VerificationQueueScreen({super.key});

  @override
  ConsumerState<VerificationQueueScreen> createState() =>
      _VerificationQueueScreenState();
}

class _VerificationQueueScreenState
    extends ConsumerState<VerificationQueueScreen> {
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    ref.read(adminProvider.notifier).loadVerificationQueue();
  }

  Future<void> _approve(int requestId) async {
    setState(() => _busy.add(requestId));
    final ok = await ref
        .read(adminProvider.notifier)
        .reviewVerification(requestId, approve: true);
    if (!mounted) return;
    setState(() => _busy.remove(requestId));
    if (ok) {
      SnackBarUtils.showSuccess(
          context, 'Badge approved — the user has been notified.');
    } else {
      SnackBarUtils.showError(context, 'Could not approve this request.');
    }
  }

  Future<void> _reject(int requestId) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject verification', style: GoogleFonts.sora()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A reason is required — it is sent to the user in the notification.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              maxLength: 1000,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              context.pop(true);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy.add(requestId));
    final ok = await ref
        .read(adminProvider.notifier)
        .reviewVerification(requestId,
            approve: false, reason: reasonController.text.trim());
    if (!mounted) return;
    setState(() => _busy.remove(requestId));
    if (ok) {
      SnackBarUtils.showSuccess(
          context, 'Verification declined — the user has been notified.');
    } else {
      SnackBarUtils.showError(context, 'Could not reject this request.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final queue = adminState.verificationQueue;

    return AdminWebLayout(
      title: 'Verification Badges',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Text(
              '${queue.length} pending badge ${queue.length == 1 ? 'request' : 'requests'}',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: adminState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : queue.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.badgeCheck,
                                size: 44, color: AppColors.textTertiary),
                            const SizedBox(height: 12),
                            Text('Queue is clear',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: queue.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _QueueTile(
                          item: queue[index],
                          busy: _busy.contains(queue[index].id),
                          onApprove: () => _approve(queue[index].id),
                          onReject: () => _reject(queue[index].id),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  final VerificationRequestItem item;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _QueueTile({
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppColors.yellowTint),
                  alignment: Alignment.center,
                  child: Text(
                    item.requesterName.isNotEmpty
                        ? item.requesterName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.sora(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(item.requesterName,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.sora(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink)),
                        ),
                        const SizedBox(width: 8),
                        StatusPill(
                            label: item.requesterRole.toUpperCase(),
                            kind: PillKind.draft),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        '${item.verifiableType} #${item.verifiableId}'
                        '${item.createdAt != null && item.createdAt!.isNotEmpty ? ' · ${item.createdAt!.split('T').first}' : ''}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Notes: ${item.notes}',
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.eye, size: 16),
                  label: Text('Docs (${item.proofMediaIds.length})',
                      style: GoogleFonts.inter(fontSize: 13)),
                  onPressed: item.proofMediaIds.isEmpty
                      ? null
                      : () => context.push(
                          '/admin/verification/${item.id}/docs',
                          extra: item),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.x,
                      size: 16, color: AppColors.error),
                  label: Text('Reject',
                      style: GoogleFonts.inter(color: AppColors.error)),
                  onPressed: busy ? null : onReject,
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(LucideIcons.check, size: 16),
                  label: Text('Approve', style: GoogleFonts.inter()),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDarker),
                  onPressed: busy ? null : onApprove,
                ),
              ],
            ),
            if (busy) ...[
              const SizedBox(height: 10),
              const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            ],
          ],
        ),
      ),
    );
  }
}
