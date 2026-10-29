import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/athlete/presentation/providers/achievements_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// AT.5 Achievements & Certificates — backed by the typed Phase-2 CRUD
/// (`/me/achievements`). Add → `/add-achievement`; delete calls DELETE.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key, this.readOnly = false});

  final bool readOnly;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    await context.push('/add-achievement');
    ref.invalidate(achievementsProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, AchievementEntry a) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete Achievement',
      message: 'Remove "${a.title}" from your profile?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(dioProvider).delete('/me/achievements/${a.id}');
      ref.invalidate(achievementsProvider);
      if (context.mounted) SnackBarUtils.showSuccess(context, 'Achievement deleted');
    } on DioException catch (e) {
      if (context.mounted) SnackBarUtils.showError(context, ApiException.fromDio(e));
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, e, 'Failed to delete achievement. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Achievements', showBack: true),
      floatingActionButton: readOnly
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.ink,
              onPressed: () => _add(context, ref),
              icon: const Icon(LucideIcons.plus),
              label: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
      body: async.when(
        loading: () => const GenericListSkeleton(),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(ApiException.messageFor(e),
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            SecondaryButton(
                label: 'Retry',
                onPressed: () => ref.invalidate(achievementsProvider)),
          ]),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: LucideIcons.award,
                title: 'No achievements yet',
                message: 'Add medals, records and certificates to stand out.',
                actionLabel: readOnly ? null : 'Add Achievement',
                onAction: readOnly ? null : () => _add(context, ref),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.refresh(achievementsProvider.future),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    for (var i = 0; i < items.length; i++) _card(context, ref, items[i]),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, AchievementEntry a) {
    return SportXCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.yellowTint,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.award,
                    size: 20, color: AppColors.warnText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title,
                        style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(LucideIcons.calendar,
                            size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(a.year,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              if (!readOnly)
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.ellipsisVertical,
                      size: 18, color: AppColors.textSecondary),
                  onSelected: (v) {
                    if (v == 'delete') _delete(context, ref, a);
                    if (v == 'edit') context.push('/add-achievement');
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          if (a.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(a.description,
                style: GoogleFonts.inter(
                    fontSize: 13.5, height: 1.45, color: AppColors.dark)),
          ],
          if (a.certificateUrl != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push(
                '/media-viewer',
                extra: {'media': [a.certificateUrl!], 'index': 0, 'title': a.title},
              ),
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.fileBadge,
                        size: 24, color: AppColors.textTertiary),
                    const SizedBox(height: 6),
                    Text('View certificate',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
