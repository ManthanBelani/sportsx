import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class _CheckItem {
  final String label;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool done;
  const _CheckItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.done,
  });
}

/// AT.6 Profile Completion Checklist — needs items with deep links.
class ProfileCompletionScreen extends StatelessWidget {
  const ProfileCompletionScreen({super.key});

  static const _items = [
    _CheckItem(
        label: 'Add a profile photo',
        subtitle: 'Photos boost discovery',
        icon: LucideIcons.camera,
        route: '/profile',
        done: true),
    _CheckItem(
        label: 'Complete identity details',
        subtitle: 'Name, location, bio, links',
        icon: LucideIcons.idCard,
        route: '/edit-profile',
        done: true),
    _CheckItem(
        label: 'Add your sports',
        subtitle: 'Sport, role, level, experience',
        icon: LucideIcons.dumbbell,
        route: '/manage-sports',
        done: true),
    _CheckItem(
        label: 'Add achievements',
        subtitle: 'Medals, records, certificates',
        icon: LucideIcons.award,
        route: '/achievements',
        done: false),
    _CheckItem(
        label: 'Upload media',
        subtitle: 'Action photos and highlight clips',
        icon: LucideIcons.imagePlus,
        route: '/media-gallery',
        done: false),
    _CheckItem(
        label: 'Verify your account',
        subtitle: 'Get the verified badge',
        icon: LucideIcons.badgeCheck,
        route: '/verification',
        done: false),
  ];

  @override
  Widget build(BuildContext context) {
    final done = _items.where((i) => i.done).length;
    final progress = done / _items.length;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Profile Completion', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          CompletionCard(
            title: 'You\'re ${(progress * 100).round()}% complete',
            subtitle: 'Finish the remaining steps to get discovered faster',
            progress: progress,
          ),
          const SizedBox(height: 18),
          Text('Suggested next steps',
              style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 12),
          for (final item in _items) _row(context, item),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, _CheckItem item) {
    return SportXCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => context.push(item.route),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.done ? const Color(0xFFDCFCE7) : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              item.done ? LucideIcons.check : item.icon,
              size: 19,
              color: item.done ? const Color(0xFF15803D) : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(item.subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (item.done)
            const StatusPill(label: 'DONE', kind: PillKind.ok)
          else
            const Icon(LucideIcons.chevronRight,
                size: 18, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
