import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class RegistrationManagementScreen extends ConsumerWidget {
  final String tournamentId;
  final String title;
  const RegistrationManagementScreen({
    super.key,
    required this.tournamentId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tournamentRegistrationsProvider(tournamentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Registrations: $title',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(tournamentRegistrationsProvider(tournamentId)),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$e', style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(tournamentRegistrationsProvider(tournamentId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (regs) => regs.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No registrations yet', style: TextStyle(color: AppColors.textSecondary))),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: regs.length,
                  itemBuilder: (context, i) {
                    final r = regs[i];
                    final name = (r['team_name'] ?? r['athlete_name'] ?? r['name'] ?? 'Participant').toString();
                    final payment = (r['payment_status'] ?? r['status'] ?? 'pending').toString();
                    final isPaid = payment == 'paid' || payment == 'completed';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTeamCard(name, isPaid),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(String name, bool isPaid) {
    final color = isPaid ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
          Row(
            children: [
              Icon(isPaid ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle, size: 16, color: color),
              const SizedBox(width: 4),
              Text(isPaid ? 'Paid' : 'Pending', style: TextStyle(color: color)),
            ],
          ),
        ],
      ),
    );
  }
}
