import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/sponsor/presentation/providers/sponsor_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class ShortlistScreen extends ConsumerWidget {
  const ShortlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shortlistProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Shortlist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(shortlistProvider.notifier).load(),
        child: state.isLoading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : state.items.isEmpty
                ? const Center(
                    child: Text('No shortlisted athletes', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (context, i) {
                      final entry = state.items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildShortlistCard(context, ref, entry),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildShortlistCard(BuildContext context, WidgetRef ref, ShortlistEntry entry) {
    return InkWell(
      onTap: () => context.push('/athlete-profile-view', extra: {'id': entry.athleteId}),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.amber.withOpacity(0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${entry.name} · ${entry.sport ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: AppColors.textSecondary, size: 18),
                  onPressed: () => ref.read(shortlistProvider.notifier).remove(entry.id),
                ),
              ],
            ),
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Note: "${entry.note}"',
                  style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}
