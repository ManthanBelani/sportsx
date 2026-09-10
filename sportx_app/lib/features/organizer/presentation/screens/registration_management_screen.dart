import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/date_format_utils.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class RegistrationManagementScreen extends ConsumerWidget {
  final String tournamentId;
  final String title;
  const RegistrationManagementScreen({super.key, required this.tournamentId, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tournamentRegistrationsProvider(tournamentId));
    final capacityAsync = ref.watch(tournamentCapacityProvider(tournamentId));
    final tournamentAsync = ref.watch(tournamentDetailProvider(tournamentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: ()=> context.pop()),
        title: const Text('Registrations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height:1, color: AppColors.border)),
      ),
      body: async.when(
        loading: ()=> const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e,_ )=> Center(child: Column(mainAxisSize: MainAxisSize.min, children:[Text('$e', style: const TextStyle(color: AppColors.textSecondary)), const SizedBox(height:12), ElevatedButton(onPressed: ()=> ref.invalidate(tournamentRegistrationsProvider(tournamentId)), child: const Text('Retry'))])),
        data: (regs) {
          // Compute summary from real backend data
          final totalTeams = regs.length;
          final capacityList = capacityAsync.valueOrNull ?? [];
          final tournament = tournamentAsync.valueOrNull;
          // Real entry fee from tournament (backend entry_fee / registration_fee) -> parse numeric
          final feeRaw = tournament?.registrationFee ?? 0;
          final feePerTeam = feeRaw > 0 ? feeRaw : 0;
          // Fallback fee from any registration category if tournament fee is 0
          final paidCount = regs.where((r) => (r['payment_status'] ?? r['status']) == 'paid').length;
          final collected = (feePerTeam > 0 ? (paidCount * feePerTeam).round() : paidCount * 2500);
          // Spots left = sum(capacity - registered) from capacity endpoint, fallback to placeholder
          int spotsLeft = 0;
          int totalCapacity = 0;
          int totalRegistered = 0;
          if (capacityList.isNotEmpty) {
            for (final c in capacityList) {
              final max = (c['max_teams'] ?? c['capacity'] ?? 0) as int;
              final reg = (c['registered'] ?? 0) as int;
              totalCapacity += max;
              totalRegistered += reg;
            }
            spotsLeft = (totalCapacity - totalRegistered).clamp(0, 9999);
          } else {
            spotsLeft = 0;
          }

          // Group by category
          final Map<String, List<Map<String,dynamic>>> grouped = {};
          for (final r in regs) {
            final catName = (r['category'] is Map ? r['category']['name'] : r['category_name'])?.toString() ?? 'Uncategorized';
            grouped.putIfAbsent(catName, ()=> []).add(r);
          }

          // Build date/venue header from real tournament detail
          final venue = tournament?.venue ?? 'Kanteerava Stadium, Bangalore';
          final dateStr = tournament?.startDate != null
              ? (tournament!.endDate != null
                  ? '${DateFormatUtils.formatShortDate(tournament.startDate!.toIso8601String())} - ${DateFormatUtils.formatShortDate(tournament.endDate!.toIso8601String())} • $venue'
                  : '${DateFormatUtils.formatShortDate(tournament.startDate!.toIso8601String())} • $venue')
              : 'Dec 15-17, 2024 • $venue';
          // fee label for per-team display (use real fee if available)
          final feeLabel = feePerTeam > 0 ? '₹${feePerTeam.toStringAsFixed(0)}' : '₹2,500';

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tournamentRegistrationsProvider(tournamentId));
              ref.invalidate(tournamentCapacityProvider(tournamentId));
              ref.invalidate(tournamentDetailProvider(tournamentId));
            },
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(child: _tournamentBar(totalTeams, collected, spotsLeft, dateStr)),
              if (regs.isEmpty)
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 80), child: Center(child: Text('No registrations yet', style: TextStyle(color: AppColors.textSecondary)))))
              else
                ...grouped.entries.map((entry)=> SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20,16,20,0),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
                        Text(entry.key, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text('${entry.value.length} teams', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 10),
                      ...entry.value.map((r){
                        final athlete = r['athlete'] is Map ? r['athlete'] as Map : null;
                        final user = athlete != null && athlete['user'] is Map ? athlete['user'] as Map : null;
                        final name = (r['team_name'] ?? r['athlete_name'] ?? user?['name'] ?? r['name'] ?? 'Participant').toString();
                        final payment = (r['payment_status'] ?? r['status'] ?? 'pending').toString();
                        final isPaid = payment=='paid' || payment=='completed';
                        // Try to get avatar
                        final avatarUrl = user?['avatar_url'] ?? athlete?['photo_url'];
                        final contact = 'Captain: ${user?['name']?.toString().split(' ').first ?? '—'} • ${r['participation_type'] ?? '—'}';
                        final feeText = isPaid ? 'Paid $feeLabel' : 'Pending';
                        final resolvedAvatar = MediaUtils.resolveNullable(avatarUrl?.toString());
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(children:[
                            CircleAvatar(radius: 18, backgroundColor: AppColors.surface, backgroundImage: resolvedAvatar!=null ? NetworkImage(resolvedAvatar) : null, onBackgroundImageError: resolvedAvatar!=null ? (e,s){} : null, child: resolvedAvatar==null ? const Icon(LucideIcons.user, size:16, color: AppColors.textSecondary) : null),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                              Text(contact, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ])),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: isPaid? const Color(0xFFd1fae5): const Color(0xFFfef3c7), borderRadius: BorderRadius.circular(4)), child: Text(feeText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isPaid? const Color(0xFF065f46): const Color(0xFF92400e)))),
                          ]),
                        );
                      }),
                      const SizedBox(height: 16),
                    ]),
                  ),
                )),
            ]),
          );
        },
      ),
    );
  }

  Widget _tournamentBar(int teams, int collected, int spotsLeft, String dateStr){
    String fmtCollected(int v){
      if (v>=100000) return '₹${(v/100000).toStringAsFixed(2)}L';
      if (v>=1000) return '₹${(v/1000).toStringAsFixed(0)}K';
      return '₹$v';
    }
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(dateStr, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Row(children:[
          Expanded(child: _summaryItem('$teams', 'Teams')),
          const SizedBox(width: 10),
          Expanded(child: _summaryItem(fmtCollected(collected), 'Collected')),
          const SizedBox(width: 10),
          Expanded(child: _summaryItem('$spotsLeft', 'Spots Left')),
        ]),
      ]),
    );
  }

  Widget _summaryItem(String num, String label){
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
      child: Column(children:[
        Text(num, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }
}
