import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_connection_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class TalentScoutConnectionsScreen extends ConsumerStatefulWidget {
  const TalentScoutConnectionsScreen({super.key});

  @override
  ConsumerState<TalentScoutConnectionsScreen> createState() => _TalentScoutConnectionsScreenState();
}

class _TalentScoutConnectionsScreenState extends ConsumerState<TalentScoutConnectionsScreen> {
  Future<void> _openChat(Map<String, dynamic>? athlete) async {
    final user = athlete?['user'] as Map<String, dynamic>?;
    final userId = user?['id'];
    final name = user?['name']?.toString() ?? athlete?['full_name']?.toString() ?? 'Athlete';
    final photoUrl = (athlete?['photo'] as Map<String, dynamic>?)?['url']?.toString() ?? '';
    if (userId == null) {
      SnackBarUtils.showError(context, 'Athlete user not found');
      return;
    }
    final (chatId, err) = await startConversationResult(ref, int.parse(userId.toString()));
    if (!mounted) return;
    if (chatId != null) {
      context.push('/chat-screen', extra: {'id': chatId, 'name': name, 'avatar': photoUrl});
    } else {
      SnackBarUtils.showError(context, err ?? 'Could not open chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scoutConnectionProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text('My Connections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(49),
            child: Column(children: [
              Container(height: 1, color: AppColors.border),
              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  const Tab(text: 'Connected'),
                  Tab(text: state.incoming.isEmpty ? 'Requests' : 'Requests (${state.incoming.length})'),
                ],
              ),
            ]),
          ),
        ),
        body: state.isLoading && state.connections.isEmpty && state.incoming.isEmpty
            ? const GenericListSkeleton()
            : state.error != null && state.connections.isEmpty && state.incoming.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.border),
                      const SizedBox(height: 12),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text(state.error!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: () => ref.read(scoutConnectionProvider.notifier).load(), style: FilledButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Retry')),
                    ]),
                  )
                : TabBarView(children: [
                    _buildConnectionsTab(ref, state.connections),
                    _buildIncomingTab(ref, state.incoming),
                  ]),
      ),
    );
  }

  Widget _buildConnectionsTab(WidgetRef ref, List<Map<String, dynamic>> connections) {
    if (connections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(LucideIcons.users, size: 48, color: AppColors.border),
            const SizedBox(height: 16),
            const Text('No connections yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Send a request from athlete profiles to start connecting', style: TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: () => context.push('/scout-discovery'), style: FilledButton.styleFrom(backgroundColor: AppColors.primary), icon: const Icon(LucideIcons.search, size: 16), label: const Text('Discover Athletes')),
          ]),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(scoutConnectionProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: connections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildConnectionItem(ref, connections[index]),
      ),
    );
  }

  Widget _buildIncomingTab(WidgetRef ref, List<Map<String, dynamic>> incoming) {
    if (incoming.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(LucideIcons.inbox, size: 48, color: AppColors.border),
            SizedBox(height: 16),
            Text('No incoming requests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            SizedBox(height: 8),
            Text('When an athlete wants to connect, it will appear here', style: TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(scoutConnectionProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: incoming.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final conn = incoming[index];
          final athlete = conn['athlete'] as Map<String, dynamic>?;
          final photoUrl = (athlete?['photo'] as Map<String, dynamic>?)?['url'] as String?;
          final name = athlete?['user']?['name']?.toString() ?? athlete?['full_name']?.toString() ?? 'Athlete';
          final connId = conn['id'].toString();
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AthleteAvatar(photoUrl: photoUrl, radius: 24),
                const SizedBox(width: 14),
                Expanded(child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFfef3c7), borderRadius: BorderRadius.circular(4)), child: const Text('New', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)))),
              ]),
              if (conn['message'] != null && conn['message'].toString().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text('"${conn['message']}"', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () async {
                  final ok = await ref.read(scoutConnectionProvider.notifier).rejectIncoming(connId);
                  if (mounted) SnackBarUtils.showSuccess(context, ok ? 'Request declined' : ref.read(scoutConnectionProvider).error ?? 'Failed');
                }, child: const Text('Decline'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(onPressed: () async {
                  final ok = await ref.read(scoutConnectionProvider.notifier).acceptIncoming(connId);
                  if (mounted) SnackBarUtils.showSuccess(context, ok ? 'Connected with $name — you can now chat' : ref.read(scoutConnectionProvider).error ?? 'Failed');
                }, style: FilledButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Accept'))),
              ]),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildConnectionItem(WidgetRef ref, Map<String, dynamic> conn) {
    final athlete = conn['athlete'] as Map<String, dynamic>?;
    final photoUrl = (athlete?['photo'] as Map<String, dynamic>?)?['url'] as String?;
    final status = (conn['status'] ?? 'pending').toString();
    final name = athlete?['user']?['name']?.toString() ?? athlete?['full_name']?.toString() ?? 'Athlete';
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

    return Semantics(
      label: 'Connection to $name, status $status',
      child: InkWell(
        onTap: () {
          if (status == 'accepted' && athlete?['id'] != null) {
            context.push('/scout-athlete/${athlete!['id']}');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            AthleteAvatar(photoUrl: photoUrl, radius: 24),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)), child: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeText))),
                if (conn['message'] != null && conn['message'].toString().isNotEmpty) ...[const SizedBox(width: 8), const Icon(LucideIcons.messageSquare, size: 12, color: AppColors.textSecondary)],
              ]),
              if (conn['message'] != null && conn['message'].toString().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 6), child: Text('"${conn['message']}"', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis)),
              if (status == 'accepted')
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: OutlinedButton.icon(
                    onPressed: () => _openChat(athlete),
                    icon: const Icon(LucideIcons.messageCircle, size: 14),
                    label: const Text('Message', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), visualDensity: VisualDensity.compact),
                  ),
                ),
            ])),
            if (status == 'pending')
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Cancel request?'),
                      content: Text('Cancel connection request to $name?'),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel request', style: TextStyle(color: Colors.red)))],
                    ),
                  );
                  if (confirm == true) {
                    final ok = await ref.read(scoutConnectionProvider.notifier).cancelConnection(connId);
                    if (mounted) SnackBarUtils.showSuccess(context, ok ? 'Request cancelled' : ref.read(scoutConnectionProvider).error ?? 'Failed to cancel');
                  }
                },
                child: const Text('Cancel', style: TextStyle(fontSize: 12, color: Colors.red)),
              )
            else
              const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
          ]),
        ),
      ),
    );
  }
}
