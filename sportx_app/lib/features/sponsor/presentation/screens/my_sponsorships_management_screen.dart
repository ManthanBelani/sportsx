import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/sponsor/presentation/providers/sponsor_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class MySponsorshipsManagementScreen extends ConsumerWidget {
  const MySponsorshipsManagementScreen({super.key});

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mySponsorshipsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text('My Sponsorships',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(mySponsorshipsProvider.notifier).refresh(),
        child: state.isLoading && state.items.isEmpty
            ? const GenericListSkeleton()
            : state.items.isEmpty
                ? const Center(
                    child: Text('No sponsorships yet', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (context, i) {
                      final s = state.items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSponsorshipCard(context, ref, s.id.toString(), s.title, s.status),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.ink,
        onPressed: () => context.push('/sponsor-posting'),
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Sponsorship'),
      ),
    );
  }

  Widget _buildSponsorshipCard(BuildContext context, WidgetRef ref, String id, String title, String status) {
    final PillKind kind;
    switch (status) {
      case 'published':
      case 'active':
        kind = PillKind.ok;
        break;
      case 'draft':
        kind = PillKind.draft;
        break;
      default:
        kind = PillKind.pending;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: SportXShadows.e1,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                StatusPill(label: _capitalize(status), kind: kind),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, color: AppColors.textSecondary),
            onSelected: (value) async {
              final actions = ref.read(sponsorshipActionsProvider);
              switch (value) {
                case 'edit':
                  context.push('/sponsor-posting');
                  break;
                case 'applications':
                  context.push('/applications-inbox');
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
              const PopupMenuItem(value: 'applications', child: Text('View Applications')),
              if (status == 'draft') const PopupMenuItem(value: 'publish', child: Text('Publish')),
              if (status == 'published') const PopupMenuItem(value: 'close', child: Text('Close')),
            ],
          ),
        ],
      ),
    );
  }
}