import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/sponsor/presentation/providers/sponsor_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class ApplicationDetailScreen extends ConsumerWidget {
  final String sponsorshipId;
  final String applicationId;
  const ApplicationDetailScreen({
    super.key,
    required this.sponsorshipId,
    required this.applicationId,
  });

  Future<void> _act(WidgetRef ref, BuildContext context, String status, String msg) async {
    final ok = await ref.read(sponsorshipActionsProvider).updateApplication(sponsorshipId, applicationId, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? msg : 'Action failed')));
      if (ok) context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Application',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Application details', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/athlete-profile-view', extra: {'id': applicationId}),
                child: const Text('View Full Profile'),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _act(ref, context, 'shortlisted', 'Added to shortlist'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    icon: const Icon(LucideIcons.star),
                    label: const Text('Shortlist'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _act(ref, context, 'approved', 'Application approved'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success)),
                    icon: const Icon(LucideIcons.check),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _act(ref, context, 'rejected', 'Application rejected'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                    icon: const Icon(LucideIcons.x),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
