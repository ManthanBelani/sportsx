import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/theme/colors.dart';

class MyTrialsManagementScreen extends ConsumerWidget {
  const MyTrialsManagementScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'published':
        return const Color(0xFF065f46);
      case 'draft':
        return const Color(0xFF92400e);
      case 'closed':
      case 'expired':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'published':
        return const Color(0xFFd1fae5);
      case 'draft':
        return const Color(0xFFfef3c7);
      default:
        return AppColors.surface;
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myTrialsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('My Trials',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myTrialsProvider.notifier).refresh(),
        child: state.isLoading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : state.items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Text('No trials posted yet', style: TextStyle(color: AppColors.textSecondary))),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (context, i) {
                      final trial = state.items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTrialCard(context, ref, trial),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/post-trial'),
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Trial'),
      ),
    );
  }

  Widget _buildTrialCard(BuildContext context, WidgetRef ref, Trial trial) {
    final status = trial.status;
    return Container(
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
                Text(trial.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                if (trial.trialDate != null)
                  Text('${trial.trialDate!.day}/${trial.trialDate!.month}/${trial.trialDate!.year} • ${trial.filledSpots ?? 0} registrations',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _statusBg(status), borderRadius: BorderRadius.circular(12)),
                  child: Text(_capitalize(status),
                      style: TextStyle(color: _statusColor(status), fontSize: 12)),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, color: AppColors.textSecondary),
            onSelected: (value) async {
              final actions = ref.read(providerTrialActionsProvider);
              switch (value) {
                case 'edit':
                  context.push('/post-trial');
                  break;
                case 'registrants':
                  context.push('/registrant-list', extra: {'id': trial.id.toString(), 'title': trial.title});
                  break;
                case 'publish':
                  await actions.publish(trial.id.toString());
                  break;
                case 'close':
                  await actions.close(trial.id.toString());
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'registrants', child: Text('View Registrants')),
              if (status == 'draft')
                const PopupMenuItem(value: 'publish', child: Text('Publish')),
              if (status == 'published')
                const PopupMenuItem(value: 'close', child: Text('Close')),
            ],
          ),
        ],
      ),
    );
  }
}
