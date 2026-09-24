import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_connection_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
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
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text('My Connections',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(49),
            child: Column(children: [
              Container(height: 1, color: AppColors.border),
              TabBar(
                labelColor: AppColors.scout,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.scout,
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
                      PrimaryButton(label: 'Retry', onPressed: () => ref.read(scoutConnectionProvider.notifier).load()),
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
            PrimaryButton(label: 'Discover Athletes', icon: LucideIcons.search, onPressed: () => context.push('/scout-discovery')),
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
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16), boxShadow: SportXShadows.e1),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AthleteAvatar(photoUrl: photoUrl, radius: 24),
                const SizedBox(width: 14),
                Expanded(child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                const StatusPill(label: 'New', kind: PillKind.pending),
              ]),
              if (conn['message'] != null && conn['message'].toString().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text('"${conn['message']}"', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: SecondaryButton(label: 'Decline', onPressed: () async {
                  final ok = await ref.read(scoutConnectionProvider.notifier).rejectIncoming(connId);
                  if (mounted) SnackBarUtils.showSuccess(context, ok ? 'Request declined' : ref.read(scoutConnectionProvider).error ?? 'Failed');
                })),
                const SizedBox(width: 12),
                Expanded(child: PrimaryButton(label: 'Accept', onPressed: () async {
                  final ok = await ref.read(scoutConnectionProvider.notifier).acceptIncoming(connId);
                  if (mounted) SnackBarUtils.showSuccess(context, ok ? 'Connected with $name — you can now chat' : ref.read(scoutConnectionProvider).error ?? 'Failed');
                })),
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

    PillKind badgeKind;
    switch (status) {
      case 'accepted':
        badgeKind = PillKind.ok;
        break;
      case 'rejected':
        badgeKind = PillKind.no;
        break;
      default:
        badgeKind = PillKind.pending;
    }

    return Semantics(
      label: 'Connection to $name, status $status',
      child: InkWell(
        onTap: () {
          if (status == 'accepted' && athlete?['id'] != null) {
            context.push('/scout-athlete/${athlete!['id']}');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16), boxShadow: SportXShadows.e1),
          child: Row(children: [
            AthleteAvatar(photoUrl: photoUrl, radius: 24),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Row(children: [
                StatusPill(label: status[0].toUpperCase() + status.substring(1), kind: badgeKind),
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
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.scout, side: const BorderSide(color: AppColors.scout), visualDensity: VisualDensity.compact),
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
