import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class OrganizerAnalyticsScreen extends ConsumerWidget {
  const OrganizerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(organizerAnalyticsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Analytics', style: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
        actions: [
          IconButton(icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.textPrimary), onPressed: () => ref.invalidate(organizerAnalyticsProvider)),
        ],
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: AppColors.border)),
      ),
      body: async.when(
        loading: () => const GenericListSkeleton(itemCount: 6),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(ApiException.messageFor(e), style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            SecondaryButton(label: 'Retry', onPressed: () => ref.invalidate(organizerAnalyticsProvider)),
          ]),
        ),
        data: (a) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(organizerAnalyticsProvider),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Summary stats grid
              Row(children: [
                Expanded(child: _statCard('${a.totalRegistrations}', 'Total Registrations', LucideIcons.users)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('${a.pendingRegistrations}', 'Pending', LucideIcons.clock, color: AppColors.amberDeep)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('${a.approvalRate}%', 'Approval Rate', LucideIcons.trendingUp, color: AppColors.success)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _statCard('${a.totalTournaments}', 'Tournaments', LucideIcons.trophy)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('${a.totalTrials}', 'Trials', LucideIcons.clipboardList)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('₹${a.revenueEstimate.toStringAsFixed(0)}', 'Revenue Est.', LucideIcons.wallet, color: AppColors.success)),
              ]),
              const SizedBox(height: 16),

              // Registrations breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: SportXShadows.e1,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Registrations Breakdown', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _breakdownItem('Approved', '${a.approvedRegistrations}', AppColors.success)),
                    Expanded(child: _breakdownItem('Pending', '${a.pendingRegistrations}', AppColors.amberDeep)),
                    Expanded(child: _breakdownItem('Rejected', '${a.rejectedRegistrations}', AppColors.error)),
                    Expanded(child: _breakdownItem('Total', '${a.totalRegistrations}', AppColors.primaryDarker)),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Row(children: [
                      if (a.approvedRegistrations > 0)
                        Expanded(flex: a.approvedRegistrations, child: Container(height: 8, color: AppColors.success)),
                      if (a.pendingRegistrations > 0)
                        Expanded(flex: a.pendingRegistrations, child: Container(height: 8, color: AppColors.amberDeep)),
                      if (a.rejectedRegistrations > 0)
                        Expanded(flex: a.rejectedRegistrations, child: Container(height: 8, color: AppColors.error)),
                      if (a.totalRegistrations == 0) Container(height: 8, color: AppColors.border),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Capacity utilization
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: SportXShadows.e1,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Capacity Utilization', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    Text('${a.utilizationPercent}%', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryDarker)),
                  ]),
                  const SizedBox(height: 8),
                  Text('${a.totalRegistered}/${a.totalCapacity} spots filled • ${a.spotsLeft} left', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: a.totalCapacity == 0 ? 0 : (a.totalRegistered / a.totalCapacity).clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: AppColors.borderSoft,
                      valueColor: const AlwaysStoppedAnimation(AppColors.ctaDark),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Tournament & Trial status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: SportXShadows.e1,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Events Status', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _eventStatusCard('Tournaments', a.publishedTournaments, a.draftTournaments, a.closedTournaments, a.totalTournaments)),
                    const SizedBox(width: 10),
                    Expanded(child: _eventStatusCard('Trials', a.publishedTrials, a.draftTrials, 0, a.totalTrials)),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),

              // Deadline alert
              if (a.deadlineAlert != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(LucideIcons.triangleAlert, size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${a.deadlineAlert!['tournament_name']} closes in ${a.deadlineAlert!['days_left']} days',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
              if (a.deadlineAlert != null) const SizedBox(height: 16),

              // Category breakdown
              if (a.categoryBreakdown.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: SportXShadows.e1,
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Capacity by Category', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 12),
                    ...a.categoryBreakdown.map((cat) {
                      final cap = (cat['capacity'] ?? 0) as int;
                      final reg = (cat['registered'] ?? 0) as int;
                      final pending = (cat['pending'] ?? 0) as int;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(child: Text('${cat['tournament_name']} • ${cat['category_name']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
                            Text('$reg/$cap', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: cap == 0 ? 0 : (reg / cap).clamp(0, 1),
                              minHeight: 6,
                              backgroundColor: AppColors.borderSoft,
                              valueColor: const AlwaysStoppedAnimation(AppColors.ctaDark),
                            ),
                          ),
                          if (pending > 0) Padding(padding: const EdgeInsets.only(top: 2), child: Text('$pending pending approval', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.amberDeep))),
                        ]),
                      );
                    }),
                  ]),
                ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, {Color color = AppColors.primary}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: SportXShadows.e1,
      ),
      child: Column(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _breakdownItem(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }

  Widget _eventStatusCard(String title, int published, int drafts, int closed, int total) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 8),
        Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('Published $published', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.yellowTint, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('Drafts $drafts', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        ]),
        if (closed > 0) ...[
          const SizedBox(height: 4),
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('Closed $closed', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ],
        const SizedBox(height: 6),
        Text('Total $total', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDarker)),
      ]),
    );
  }
}
