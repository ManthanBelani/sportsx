import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/role_config.dart';
import 'package:sportx_app/shared/providers/role_config_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

/// S.8 Create — full-tab launcher (design: tilegrid + Quick Post Options).
/// Same [roleConfigProvider] data that now feeds the Create FAB, so every
/// role keeps its own action set without duplicated UI.
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
      appBar: SportXTopBar(title: 'Create'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
        children: [
          Text('Share, Add or Create on SportX',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 84,
            ),
            itemCount: tiles.length,
            itemBuilder: (_, i) => _CreateTileCard(tile: tiles[i], index: i),
          ),
          const SizedBox(height: 14),
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
                Text('Quick Post Options',
                    style: GoogleFonts.sora(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 3),
                Text('Share something quickly',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
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
                      if (q != const (icon: LucideIcons.award, label: 'Achievement')) const SizedBox(width: 8),
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

/// Design pastel squares (CREATE_TILES[5]): #FDE8E8/#DFF5E3/#E3EFFF/#FFF3D6/#ECE6FB,
/// cycled by index so the grid keeps the same rhythm as the prototype.
const _ctilePastels = [
  Color(0xFFFDE8E8),
  Color(0xFFDFF5E3),
  Color(0xFFE3EFFF),
  Color(0xFFFFF3D6),
  Color(0xFFECE6FB),
];

const _ctilePastelFg = [
  Color(0xFFD9534F),
  Color(0xFF3FA55C),
  Color(0xFF3B82F6),
  Color(0xFF8A6D00),
  Color(0xFF8A6AEA),
];

class _CreateTileCard extends StatelessWidget {
  final CreateTile tile;
  final int index;
  const _CreateTileCard({required this.tile, required this.index});

  @override
  Widget build(BuildContext context) {
    final bg = _ctilePastels[index % _ctilePastels.length];
    final fg = _ctilePastelFg[index % _ctilePastelFg.length];
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Icon(tile.icon, size: 22, color: fg),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tile.label,
                      maxLines: 2,
                      style:
                          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.25)),
                  if (tile.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(tile.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary, height: 1.45)),
                  ],
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 15, color: AppColors.textTertiary),
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
            Text(q.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.dark)),
          ],
        ),
      ),
    );
  }
}
