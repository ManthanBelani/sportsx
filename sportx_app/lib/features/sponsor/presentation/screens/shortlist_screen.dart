import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/sponsor/presentation/providers/sponsor_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class ShortlistScreen extends ConsumerWidget {
  const ShortlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shortlistProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text('Shortlist',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(shortlistProvider.notifier).load(),
        child: state.isLoading && state.items.isEmpty
            ? const GenericListSkeleton()
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
    return EntityRow(
      title: '${entry.name} · ${entry.sport ?? ''}',
      subtitle: entry.note != null && entry.note!.isNotEmpty ? 'Note: "${entry.note}"' : 'Shortlisted athlete',
      avatarText: entry.name.isNotEmpty ? entry.name[0].toUpperCase() : 'A',
      onTap: () => context.push('/athlete-profile-view', extra: {'id': entry.athleteId}),
      trailing: IconButton(
        icon: const Icon(LucideIcons.trash2, color: AppColors.textSecondary, size: 18),
        onPressed: () => ref.read(shortlistProvider.notifier).remove(entry.id),
      ),
    );
  }
}
