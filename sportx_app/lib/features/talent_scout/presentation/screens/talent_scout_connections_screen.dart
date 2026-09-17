import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_connection_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class TalentScoutConnectionsScreen extends ConsumerWidget {
  const TalentScoutConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scoutConnectionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('My Connections',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.pop()),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: state.isLoading
          ? const GenericListSkeleton()
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.border),
                      const SizedBox(height: 16),
                      Text(state.error!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.read(scoutConnectionProvider.notifier).load(),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.connections.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.users, size: 48, color: AppColors.border),
                          SizedBox(height: 16),
                          Text('No connections yet',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                          SizedBox(height: 8),
                          Text('Send a request from athlete profiles', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(scoutConnectionProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.connections.length,
                        itemBuilder: (context, index) {
                          final conn = state.connections[index];
                          return _buildConnectionItem(context, ref, conn);
                        },
                      ),
                    ),
    );
  }

  Widget _buildConnectionItem(BuildContext context, WidgetRef ref, Map<String, dynamic> conn) {
    final athlete = conn['athlete'] as Map<String, dynamic>?;
    final photoUrl = athlete?['photo']?['url'] as String?;
    final status = (conn['status'] ?? 'pending').toString();
    final name = athlete?['user']?['name'] ?? 'Athlete';
    final connId = conn['id'].toString();

    Color badgeColor;
    Color badgeText;
    switch (status) {
      case 'accepted':
        badgeColor = const Color(0xFFd1fae5);
        badgeText = const Color(0xFF065f46);
        break;
      case 'rejected':
        badgeColor = const Color(0xFFfee2e2);
        badgeText = const Color(0xFF991b1b);
        break;
      default:
        badgeColor = const Color(0xFFfef3c7);
        badgeText = const Color(0xFF92400E);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          AthleteAvatar(photoUrl: photoUrl, radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)),
                    child: Text(status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeText)),
                  ),
                  if (conn['message'] != null && conn['message'].toString().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.messageSquare, size: 12, color: AppColors.textSecondary),
                  ],
                ]),
                if (conn['message'] != null && conn['message'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('"${conn['message']}"', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          if (status == 'pending')
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cancel request?'),
                    content: Text('Cancel connection request to $name?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel request', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  final ok = await ref.read(scoutConnectionProvider.notifier).cancelConnection(connId);
                  if (context.mounted) {
                    SnackBarUtils.showSuccess(context, ok ? 'Request cancelled' : 'Failed to cancel');
                  }
                }
              },
              child: const Text('Cancel', style: TextStyle(fontSize: 12, color: Colors.red)),
            )
          else
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}