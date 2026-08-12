import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class RegistrantListScreen extends ConsumerWidget {
  final String trialId;
  final String title;
  const RegistrantListScreen({super.key, required this.trialId, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trialRegistrantsProvider(trialId));
    final regs = async.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Registrants: $title',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${regs.length} registered', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(trialRegistrantsProvider(trialId)),
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$e', style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(trialRegistrantsProvider(trialId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (items) => items.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 200),
                        Center(child: Text('No registrants yet', style: TextStyle(color: AppColors.textSecondary))),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final r = items[i];
                          final name = (r['athlete_name'] ?? r['name'] ?? 'Athlete').toString();
                          final status = (r['status'] ?? 'pending').toString();
                          final verified = status == 'verified' || status == 'approved';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildRegistrantCard(context, name, verified, r['id']?.toString() ?? ''),
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

  Widget _buildRegistrantCard(BuildContext context, String name, bool verified, String id) {
    final color = verified ? AppColors.success : AppColors.warning;
    return InkWell(
      onTap: () => context.push('/registrant-detail', extra: {'id': id}),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Status: ', style: TextStyle(color: AppColors.textSecondary)),
                      Icon(verified ? LucideIcons.checkCircle2 : LucideIcons.clock, size: 16, color: color),
                      const SizedBox(width: 4),
                      Text(verified ? 'Verified' : 'Pending', style: TextStyle(color: color)),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/registrant-detail', extra: {'id': id}),
              child: const Text('View →'),
            ),
          ],
        ),
      ),
    );
  }
}
