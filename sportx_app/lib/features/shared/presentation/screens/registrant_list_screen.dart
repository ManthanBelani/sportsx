import 'package:flutter/material.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/date_format_utils.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Registrants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                Text('$filled/$capacity registered', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
                    ? ListView(children: const [SizedBox(height: 200), Center(child: Text('No registrants yet', style: TextStyle(color: AppColors.textSecondary)))])
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
                            child: _buildRegistrantCard(context, name, phone.toString(), age.toString(), gender.toString(), isDocsComplete, approvalStatus, r['id']?.toString() ?? '', photoUrl?.toString()),
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

  Widget _buildRegistrantCard(BuildContext context, String name, String phone, String age, String gender, bool docsComplete, String approvalStatus, String id, String? photoUrl) {
    final docsColor = docsComplete ? const Color(0xFFd1fae5) : const Color(0xFFfef3c7);
    final docsTextColor = docsComplete ? const Color(0xFF065f46) : const Color(0xFF92400E);
    final isApproved = approvalStatus == 'approved';
    final isRejected = approvalStatus == 'rejected';
    final statusColor = isApproved ? AppColors.success : isRejected ? Colors.red : AppColors.warning;
    final statusLabel = isApproved ? 'Approved' : isRejected ? 'Rejected' : 'Pending';
    return InkWell(
      onTap: () => context.push('/registrant-detail', extra: {'id': id}),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
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
              Text('Age $age • $gender', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
              child: Text(docsComplete ? 'Complete' : 'Pending', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: docsTextColor)),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Icon(isApproved ? LucideIcons.checkCircle2 : isRejected ? LucideIcons.xCircle : LucideIcons.clock, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
            ]),
          ]),
        ]),
      ),
    );
  }
}
