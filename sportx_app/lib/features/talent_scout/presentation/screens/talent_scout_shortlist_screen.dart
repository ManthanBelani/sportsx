import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_shortlist_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class TalentScoutShortlistScreen extends ConsumerWidget {
  const TalentScoutShortlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scoutShortlistProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('My Shortlist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.pop()),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.star, size: 48, color: AppColors.border),
                      SizedBox(height: 16),
                      Text('No athletes shortlisted yet', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      SizedBox(height: 8),
                      Text('Discover athletes and tap ⭐ to save', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(scoutShortlistProvider.notifier).load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return _buildShortlistItem(context, ref, item);
                    },
                  ),
                ),
    );
  }

  Widget _buildShortlistItem(BuildContext context, WidgetRef ref, dynamic item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove from Shortlist'),
            content: Text('Remove ${item.athlete.fullName} from your shortlist?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        final success = await ref.read(scoutShortlistProvider.notifier).removeFromShortlist(item.athlete.id);
        if (context.mounted) {
          SnackBarUtils.showSuccess(context, success ? 'Removed from shortlist' : 'Failed to remove');
        }
      },
      child: GestureDetector(
        onTap: () => context.push('/scout-athlete/${item.athlete.id}'),
        onLongPress: () => _showNotesDialog(context, ref, item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AthleteAvatar(photoUrl: item.athlete.photoUrl, radius: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.athlete.fullName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Row(children: [
                          if (item.athlete.sports.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                              child: Text(item.athlete.sports.first, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ),
                          if (item.athlete.cityName != null) ...[
                            const SizedBox(width: 6),
                            Text(item.athlete.cityName!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(LucideIcons.moreVertical, size: 18, color: AppColors.textSecondary),
                    onSelected: (v) {
                      if (v == 'notes') _showNotesDialog(context, ref, item);
                      if (v == 'view') context.push('/scout-athlete/${item.athlete.id}');
                      if (v == 'connect') context.push('/scout-connect/${item.athlete.id}');
                      if (v == 'remove') {
                        ref.read(scoutShortlistProvider.notifier).removeFromShortlist(item.athlete.id);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'view', child: Text('View profile')),
                      const PopupMenuItem(value: 'notes', child: Text('Edit notes')),
                      const PopupMenuItem(value: 'connect', child: Text('Connect')),
                      const PopupMenuItem(value: 'remove', child: Text('Remove', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              if (item.notes != null && item.notes.toString().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(LucideIcons.stickyNote, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(item.notes, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                  ]),
                ),
              ] else ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _showNotesDialog(context, ref, item),
                  child: const Row(children: [
                    Icon(LucideIcons.plus, size: 12, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text('Add note', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showNotesDialog(BuildContext context, WidgetRef ref, dynamic item) {
    final ctrl = TextEditingController(text: item.notes ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Notes for ${item.athlete.fullName}'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'e.g. Strong left-footed striker, observed at Junior Nationals...', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref.read(scoutShortlistProvider.notifier).updateNotes(item.athlete.id, ctrl.text.trim());
              if (context.mounted) {
                SnackBarUtils.showSuccess(context, ok ? 'Notes updated' : 'Failed to update notes');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
