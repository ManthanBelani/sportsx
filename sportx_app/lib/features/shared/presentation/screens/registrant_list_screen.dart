import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/date_format_utils.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class RegistrantListScreen extends ConsumerWidget {
  final String trialId;
  final String title;
  const RegistrantListScreen({super.key, required this.trialId, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trialRegistrantsProvider(trialId));
    final trialAsync = ref.watch(trialDetailProvider(trialId));
    final trial = trialAsync.valueOrNull;
    final regs = async.valueOrNull ?? [];

    final trialDateStr = trial != null && trial.trialDate != null
        ? DateFormatUtils.formatShortDate(trial.trialDate!.toIso8601String())
        : 'Dec 10, 2024';
    final capacity = 50;
    final filled = regs.length;
    final progress = capacity == 0 ? 0.0 : (filled / capacity).clamp(0, 1).toDouble();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text('Registrants',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: Column(
        children: [
          // Trial header bar per design academy/registrant-list.html
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(LucideIcons.calendar, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(trialDateStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                const Text('• 8:00 AM - 12:00 PM', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                Text('$filled/$capacity registered', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
              ),
            ]),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(trialRegistrantsProvider(trialId)),
              child: async.when(
                loading: () => const GenericListSkeleton(itemCount: 5),
                error: (e, _) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(ApiException.messageFor(e), style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: () => ref.invalidate(trialRegistrantsProvider(trialId)), child: const Text('Retry')),
                  ]),
                ),
                data: (items) => items.isEmpty
                    ? ListView(children:  [SizedBox(height: 200), Center(child: Text('No registrants yet', style: GoogleFonts.inter(color: AppColors.textSecondary)))])
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final r = items[i];
                          final name = (r['athlete_name'] ?? r['name'] ?? r['athlete']?['user']?['name'] ?? 'Athlete').toString();
                          final athlete = r['athlete'] as Map<String, dynamic>?;
                          final user = athlete?['user'] as Map<String, dynamic>?;
                          final phone = r['phone'] ?? athlete?['phone'] ?? user?['phone'] ?? '+91 98765 43210';
                          final age = r['age'] ?? athlete?['age_group']?['name'] ?? '14';
                          final gender = r['gender'] ?? athlete?['gender'] ?? '—';
                          final approvalStatus = (r['approval_status'] ?? r['status'] ?? 'pending').toString();
                          final docsStatus = (r['document_status'] ?? 'pending').toString();
                          final isDocsComplete = docsStatus == 'submitted' || docsStatus == 'complete';
                          final photoUrl = user?['avatar_url'] ?? athlete?['photo']?['url'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RegistrantCardWithActions(
                              trialId: trialId,
                              name: name,
                              phone: phone.toString(),
                              age: age.toString(),
                              gender: gender.toString(),
                              isDocsComplete: isDocsComplete,
                              approvalStatus: approvalStatus,
                              id: r['id']?.toString() ?? '',
                              photoUrl: photoUrl?.toString(),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _RegistrantCardWithActions extends ConsumerWidget {
  final String trialId;
  final String name;
  final String phone;
  final String age;
  final String gender;
  final bool isDocsComplete;
  final String approvalStatus;
  final String id;
  final String? photoUrl;

  const _RegistrantCardWithActions({
    required this.trialId,
    required this.name,
    required this.phone,
    required this.age,
    required this.gender,
    required this.isDocsComplete,
    required this.approvalStatus,
    required this.id,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsColor = isDocsComplete ? AppColors.successLight : AppColors.yellowTint;
    final docsTextColor = isDocsComplete ? AppColors.success : AppColors.warnText;
    final isApproved = approvalStatus == 'approved';
    final isRejected = approvalStatus == 'rejected';
    final isPending = approvalStatus == 'pending';
    final statusColor = isApproved ? AppColors.success : isRejected ? Colors.red : AppColors.warning;
    final statusLabel = isApproved ? 'Approved' : isRejected ? 'Rejected' : 'Pending';
    return InkWell(
      onTap: () => context.push('/registrant-detail', extra: {'id': id}),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: MediaUtils.resolveNullable(photoUrl) != null ? NetworkImage(MediaUtils.resolveUrl(photoUrl)) : null,
              onBackgroundImageError: MediaUtils.resolveNullable(photoUrl) != null ? (e, s) {} : null,
              child: MediaUtils.resolveNullable(photoUrl) == null ? const Icon(LucideIcons.user, color: AppColors.primary, size: 20) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Age $age • $gender', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(LucideIcons.phone, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: docsColor, borderRadius: BorderRadius.circular(4)),
                child: Text(isDocsComplete ? 'Complete' : 'Pending', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: docsTextColor)),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Icon(isApproved ? LucideIcons.checkCircle2 : isRejected ? LucideIcons.xCircle : LucideIcons.clock, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ]),
            ]),
          ]),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(onPressed: () => _reject(context, ref), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)), child: const Text('Reject', style: TextStyle(fontSize: 12))),
              const SizedBox(width: 8),
              FilledButton(onPressed: () => _approve(context, ref), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)), child: const Text('Approve', style: TextStyle(fontSize: 12))),
            ]),
          ],
        ]),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final (ok, err) = await ref.read(providerTournamentActionsProvider).approveTrialRegistration(id);
    if (context.mounted) {
      if (ok) {
        SnackBarUtils.showSuccess(context, 'Registration approved');
        ref.invalidate(trialRegistrantsProvider(trialId));
      } else {
        SnackBarUtils.showError(context, err ?? 'Failed to approve');
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Registration'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Reason for rejection', hintText: 'Enter reason...'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Reject')),
        ],
      ),
    );
    if (reason != null && reason.trim().isNotEmpty && context.mounted) {
      final (ok, err) = await ref.read(providerTournamentActionsProvider).rejectTrialRegistration(id, reason.trim());
      if (context.mounted) {
        if (ok) {
          SnackBarUtils.showSuccess(context, 'Registration rejected');
          ref.invalidate(trialRegistrantsProvider(trialId));
        } else {
          SnackBarUtils.showError(context, err ?? 'Failed to reject');
        }
      }
    }
  }
}
