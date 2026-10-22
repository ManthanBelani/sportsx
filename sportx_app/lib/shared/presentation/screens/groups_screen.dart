import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sportx_app/core/config/api_config.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/social/presentation/providers/groups_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// S.13 Community — Groups. Lists the real groups from the API with
/// server-backed join/leave (the previous build rendered hardcoded samples).
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Groups', showBack: true),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(groupsProvider),
        child: groupsAsync.when(
          loading: () => const GenericListSkeleton(),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 100),
              const EmptyState(
                icon: LucideIcons.users,
                title: 'Could not load groups',
                message: 'Pull to retry.',
              ),
              Center(
                child: SecondaryButton(
                  label: 'Retry',
                  onPressed: () => ref.invalidate(groupsProvider),
                ),
              ),
            ],
          ),
          data: (groups) => groups.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    EmptyState(
                      icon: LucideIcons.users,
                      title: 'No groups yet',
                      message: 'Interest groups will appear here.',
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [for (final g in groups) _card(context, ref, g)],
                ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, Group g) {
    return SportXCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () =>
          context.push('/group-detail', extra: {'id': g.id, 'name': g.name}),
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
            child: const Icon(
              LucideIcons.users,
              size: 22,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_typeLabel(g.type)} · ${g.memberCount} members',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (g.isMember)
            const StatusPill(label: 'JOINED', kind: PillKind.ok)
          else
            PrimaryButton(
              label: 'Join',
              small: true,
              onPressed: () async {
                final ok = await joinGroup(ref, g.id);
                if (!context.mounted) return;
                if (ok) {
                  SnackBarUtils.showSuccess(context, 'Joined ${g.name}');
                } else {
                  SnackBarUtils.showError(context, 'Could not join the group.');
                }
              },
            ),
        ],
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
    'coaching' => 'Coaching',
    'athletes' => 'Athletes',
    'trials' => 'Trials',
    _ => 'General',
  };
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
                Text(
                  name,
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Members and posts from this group appear here.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Share',
                        icon: LucideIcons.share2,
                        onPressed: () {
                          final url = '${ApiConfig.webBaseUrl}/groups';
                          Share.share('Join "$name" on SportX\n$url');
                        },
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
