import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/models/approval.dart';
import 'package:sportx_app/shared/providers/registration_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class MyRegistrationsScreen extends ConsumerWidget {
  const MyRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.88),
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          title: Text('My Registrations',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'Tournaments'), Tab(text: 'Trials')],
          ),
        ),
        body: TabBarView(
          children: [
            _TournamentRegsView(ref: ref),
            _TrialRegsView(ref: ref),
          ],
        ),
      ),
    );
  }
}

ApprovalStatus _parseApprovalStatus(String? value) => ApprovalStatusX.fromString(value);

Color _approvalColor(ApprovalStatus status) => switch (status) {
      ApprovalStatus.approved => AppColors.success,
      ApprovalStatus.rejected => AppColors.error,
      ApprovalStatus.pending => AppColors.warning,
    };

IconData _approvalIcon(ApprovalStatus status) => switch (status) {
      ApprovalStatus.approved => LucideIcons.checkCircle,
      ApprovalStatus.rejected => LucideIcons.xCircle,
      ApprovalStatus.pending => LucideIcons.hourglass,
    };

class _TournamentRegsView extends StatelessWidget {
  final WidgetRef ref;
  const _TournamentRegsView({required this.ref});

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myTournamentRegistrationsProvider);
    return async.when(
      loading: () => const GenericListSkeleton(),
      error: (e, _) => Center(child: Text(ApiException.messageFor(e))),
      data: (regs) {
        if (regs.isEmpty) {
          return const Center(
              child: Text('No tournament registrations yet',
                  style: TextStyle(color: AppColors.textSecondary)));
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(myTournamentRegistrationsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: regs.length,
            itemBuilder: (context, i) {
              final reg = regs[i];
              final approvalStr = (reg['approval_status'] ?? 'pending').toString();
              final approvalStatus = _parseApprovalStatus(approvalStr);
              final tournament = reg['tournament'] is Map ? Map<String, dynamic>.from(reg['tournament'] as Map) : null;
              final category = reg['category'] is Map ? Map<String, dynamic>.from(reg['category'] as Map) : null;
              final tournamentName = tournament?['name']?.toString() ?? tournament?['title']?.toString() ?? 'Tournament #${reg['tournament_id']}';
              final categoryName = category?['name']?.toString();
              final rejectionReason = reg['rejection_reason']?.toString();
              final color = _approvalColor(approvalStatus);
              return Card(
                child: ListTile(
                  title: Text(tournamentName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (categoryName != null) Text('Category: $categoryName'),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(approvalStatus.label,
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                        backgroundColor: color,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      if (approvalStatus == ApprovalStatus.rejected && (rejectionReason?.isNotEmpty == true))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Reason: $rejectionReason',
                              style: const TextStyle(color: AppColors.error, fontSize: 12)),
                        ),
                    ],
                  ),
                  trailing: Icon(_approvalIcon(approvalStatus), color: color),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _TrialRegsView extends StatelessWidget {
  final WidgetRef ref;
  const _TrialRegsView({required this.ref});

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myTrialRegistrationsProvider);
    return async.when(
      loading: () => const GenericListSkeleton(),
      error: (e, _) => Center(child: Text(ApiException.messageFor(e))),
      data: (regs) {
        if (regs.isEmpty) {
          return const Center(
              child: Text('No trial registrations yet',
                  style: TextStyle(color: AppColors.textSecondary)));
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(myTrialRegistrationsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: regs.length,
            itemBuilder: (context, i) {
              final reg = regs[i];
              final approvalStr = (reg['approval_status'] ?? 'pending').toString();
              final approvalStatus = _parseApprovalStatus(approvalStr);
              final trial = reg['trial'] is Map ? Map<String, dynamic>.from(reg['trial'] as Map) : null;
              final trialName = trial?['name']?.toString() ?? trial?['title']?.toString() ?? 'Trial #${reg['trial_id']}';
              final registrationRef = reg['registration_ref']?.toString() ?? '';
              final rejectionReason = reg['rejection_reason']?.toString();
              final color = _approvalColor(approvalStatus);
              return Card(
                child: ListTile(
                  title: Text(trialName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ref: $registrationRef'),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(approvalStatus.label,
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                        backgroundColor: color,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      if (approvalStatus == ApprovalStatus.rejected && (rejectionReason?.isNotEmpty == true))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Reason: $rejectionReason',
                              style: const TextStyle(color: AppColors.error, fontSize: 12)),
                        ),
                    ],
                  ),
                  trailing: Icon(_approvalIcon(approvalStatus), color: color),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}