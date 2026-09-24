import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/sponsor/presentation/providers/sponsor_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

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
      if (ok) {
  SnackBarUtils.showSuccess(context, msg);
} else {
  SnackBarUtils.showError(context, 'Action failed');
}
      if (ok) context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text('Application',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
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
              child: SecondaryButton(
                label: 'View Full Profile',
                icon: LucideIcons.user,
                onPressed: () => context.push('/athlete-profile-view', extra: {'id': applicationId}),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Shortlist',
                    icon: LucideIcons.star,
                    small: true,
                    onPressed: () => _act(ref, context, 'shortlisted', 'Added to shortlist'),
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
