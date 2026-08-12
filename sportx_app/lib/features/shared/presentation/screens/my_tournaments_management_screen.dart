import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class MyTournamentsManagementScreen extends ConsumerWidget {
  const MyTournamentsManagementScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'published':
      case 'active':
        return AppColors.success;
      case 'draft':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myTournamentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('My Tournaments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myTournamentsProvider.notifier).refresh(),
        child: state.isLoading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : state.items.isEmpty
                ? const Center(
                    child: Text('No tournaments yet', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (context, i) {
                      final t = state.items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTournamentCard(context, ref, t.id.toString(), t.title, t.status),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/post-tournament'),
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Tournament'),
      ),
    );
  }

  Widget _buildTournamentCard(BuildContext context, WidgetRef ref, String id, String title, String status) {
    final color = _statusColor(status);
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text(_capitalize(status), style: TextStyle(color: color, fontSize: 12)),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, color: AppColors.textSecondary),
            onSelected: (value) async {
              final actions = ref.read(providerTournamentActionsProvider);
              switch (value) {
                case 'edit':
                  context.push('/post-tournament');
                  break;
                case 'registrations':
                  context.push('/registration-management', extra: {'id': id, 'title': title});
                  break;
                case 'results':
                  context.push('/results-publishing', extra: {'id': id, 'title': title});
                  break;
                case 'publish':
                  await actions.publish(id);
                  break;
                case 'close':
                  await actions.close(id);
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'registrations', child: Text('Registrations')),
              const PopupMenuItem(value: 'results', child: Text('Results')),
              if (status == 'draft') const PopupMenuItem(value: 'publish', child: Text('Publish')),
              if (status == 'published') const PopupMenuItem(value: 'close', child: Text('Close')),
            ],
          ),
        ],
      ),
    );
  }
}
