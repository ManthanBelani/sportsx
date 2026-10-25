import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/role_config.dart';
import 'package:sportx_app/shared/providers/role_config_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

/// S.8 Create — the design board's "Create" tab: a vertical list of rows,
/// each a pastel circle icon + title + subtitle + chevron (screen 3 of the
/// organizer board). The rows come from [roleConfigProvider], so every role
/// keeps its own action set without duplicated UI.
class CreateScreen extends ConsumerWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = ref
        .watch(roleConfigProvider)
        .createTiles
        .where((t) => t.priority != CreatePriority.p2)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SportXTopBar(
        title: 'Create',
        showBack: true,
        // Create is a shell tab, so a tap on the arrow returns to the previous
        // tab (or Home when it was opened directly).
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(ref.watch(roleConfigProvider).homeRoute);
          }
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          for (final tile in tiles) ...[
            _CreateRow(tile: tile),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: SportXShadows.e1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Post Options',
                  style: GoogleFonts.sora(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Share something quickly',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final q in const [
                      (icon: LucideIcons.image, label: 'Photo'),
                      (icon: LucideIcons.video, label: 'Video'),
                      (icon: LucideIcons.type, label: 'Text'),
                      (icon: LucideIcons.barChart2, label: 'Poll'),
                      (icon: LucideIcons.award, label: 'Achievement'),
                    ]) ...[
                      Expanded(child: _QuickPostCell(q: q)),
                      if (q !=
                          const (icon: LucideIcons.award, label: 'Achievement'))
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Design board · CreateRow — 44px pastel circle, title + subtitle, chevron.
class _CreateRow extends StatelessWidget {
  final CreateTile tile;
  const _CreateRow({required this.tile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(tile.route),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tile.tintBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(tile.icon, size: 20, color: tile.tintFg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tile.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if (tile.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      tile.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPostCell extends StatelessWidget {
  final ({IconData icon, String label}) q;
  const _QuickPostCell({required this.q});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/create-post'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(q.icon, size: 20, color: AppColors.dark),
            const SizedBox(height: 5),
            Text(
              q.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
