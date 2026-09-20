import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';

class OrganizerAnalyticsScreen extends ConsumerWidget {
  const OrganizerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(organizerAnalyticsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
            ElevatedButton(onPressed: () => ref.invalidate(organizerAnalyticsProvider), child: const Text('Retry')),
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
                Expanded(child: _statCard('${a.pendingRegistrations}', 'Pending', LucideIcons.clock, color: Colors.orange)),
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
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Registrations Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _breakdownItem('Approved', '${a.approvedRegistrations}', AppColors.success)),
                    Expanded(child: _breakdownItem('Pending', '${a.pendingRegistrations}', Colors.orange)),
                    Expanded(child: _breakdownItem('Rejected', '${a.rejectedRegistrations}', Colors.red)),
                    Expanded(child: _breakdownItem('Total', '${a.totalRegistrations}', AppColors.primary)),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(children: [
                      if (a.approvedRegistrations > 0)
                        Expanded(flex: a.approvedRegistrations, child: Container(height: 8, color: AppColors.success)),
                      if (a.pendingRegistrations > 0)
                        Expanded(flex: a.pendingRegistrations, child: Container(height: 8, color: Colors.orange)),
                      if (a.rejectedRegistrations > 0)
                        Expanded(flex: a.rejectedRegistrations, child: Container(height: 8, color: Colors.red)),
                      if (a.totalRegistrations == 0) Container(height: 8, color: AppColors.border),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Capacity utilization
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Capacity Utilization', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('${a.utilizationPercent}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 8),
                  Text('${a.totalRegistered}/${a.totalCapacity} spots filled • ${a.spotsLeft} left', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: a.totalCapacity == 0 ? 0 : (a.totalRegistered / a.totalCapacity).clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Tournament & Trial status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Events Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                  decoration: BoxDecoration(color: const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(LucideIcons.clock, size: 18, color: Color(0xFFdc2626)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${a.deadlineAlert!['tournament_name']} closes in ${a.deadlineAlert!['days_left']} days',
                        style: const TextStyle(fontSize: 13, color: Color(0xFFdc2626), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
              if (a.deadlineAlert != null) const SizedBox(height: 16),

              // Category breakdown
              if (a.categoryBreakdown.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Capacity by Category', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: cap == 0 ? 0 : (reg / cap).clamp(0, 1),
                              minHeight: 6,
                              backgroundColor: AppColors.border,
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                          if (pending > 0) Padding(padding: const EdgeInsets.only(top: 2), child: Text('$pending pending approval', style: const TextStyle(fontSize: 11, color: Colors.orange))),
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
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _breakdownItem(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }

  Widget _eventStatusCard(String title, int published, int drafts, int closed, int total) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFd1fae5), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('Published $published', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFfef3c7), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('Drafts $drafts', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
        if (closed > 0) ...[
          const SizedBox(height: 4),
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('Closed $closed', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ],
        const SizedBox(height: 6),
        Text('Total $total', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ]),
    );
  }
}
