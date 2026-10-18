import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class GroupItem {
  final String id;
  final String name;
  final String category;
  final int members;
  final bool joined;
  const GroupItem({
    required this.id,
    required this.name,
    required this.category,
    required this.members,
    this.joined = false,
  });
}

/// S.13 Community — Groups (P2). Presentation-first: local join toggling.
/// Wire to a `groupsProvider` when the community API lands.
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  static const _sample = [
    GroupItem(id: 'g1', name: 'Cricket Coaches India', category: 'Professional', members: 1240),
    GroupItem(id: 'g2', name: 'U-16 Football Parents', category: 'Interest', members: 486),
    GroupItem(id: 'g3', name: 'Gujarat Athletics', category: 'Regional', members: 932, joined: true),
  ];

  final Set<String> _joined = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Groups', showBack: true),
      body: _sample.isEmpty
          ? const EmptyState(
              icon: LucideIcons.users,
              title: 'No groups yet',
              message: 'Interest groups will appear here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                for (final g in _sample) _card(context, g),
              ],
            ),
    );
  }

  Widget _card(BuildContext context, GroupItem g) {
    final joined = g.joined || _joined.contains(g.id);
    return SportXCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.push('/group-detail',
          extra: {'id': g.id, 'name': g.name}),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.users,
                size: 22, color: AppColors.info),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.name,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('${g.category} · ${g.members} members',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (joined)
            const StatusPill(label: 'JOINED', kind: PillKind.ok)
          else
            PrimaryButton(
              label: 'Join',
              small: true,
              onPressed: () => setState(() => _joined.add(g.id)),
            ),
        ],
      ),
    );
  }
}

/// S.14 Group Detail (P2).
class GroupDetailScreen extends StatelessWidget {
  final String name;
  final String? groupId;

  const GroupDetailScreen({super.key, required this.name, this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Group', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SportXCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 6),
                Text('Members and posts from this group appear here.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Joined',
                        icon: LucideIcons.check,
                        small: true,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SecondaryButton(
                        label: 'Share',
                        icon: LucideIcons.share2,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const EmptyState(
            icon: LucideIcons.messageSquare,
            title: 'No posts yet',
            message: 'Be the first to post in this group.',
          ),
        ],
      ),
    );
  }
}
