import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/connections_provider.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class MyConnectionsScreen extends ConsumerStatefulWidget {
  const MyConnectionsScreen({super.key});

  @override
  ConsumerState<MyConnectionsScreen> createState() => _MyConnectionsScreenState();
}

class _MyConnectionsScreenState extends ConsumerState<MyConnectionsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider).user?.id.toString() ?? '';
    final async = ref.watch(myConnectionsProvider(currentUserId));
    final query = _searchQuery.toLowerCase();
    final connections = (async.valueOrNull ?? [])
        .where((c) => c.other.name.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text('My Connections',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.userSearch, color: AppColors.textPrimary),
            tooltip: 'Find athletes',
            onPressed: () => context.push('/athlete-directory'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.userPlus, color: AppColors.textPrimary),
            onPressed: () => context.push('/connection-requests'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search connections...',
                prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(myConnectionsProvider(currentUserId)),
              child: async.when(
                loading: () => const ConnectionsSkeleton(),
                error: (e, _) => Center(child: Text(ApiException.messageFor(e), style: const TextStyle(color: AppColors.textSecondary))),
                data: (_) => connections.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 200),
                        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(LucideIcons.users, size: 64, color: AppColors.textTertiary),
                          const SizedBox(height: 16),
                          Text('No connections yet', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          PrimaryButton(
                            label: 'Find Athletes',
                            icon: LucideIcons.userSearch,
                            onPressed: () => context.push('/athlete-directory'),
                          ),
                        ])),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: connections.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _buildConnectionTile(connections[index], currentUserId),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionTile(ConnectionRecord connection, String currentUserId) {
    final initial = connection.other.name.isNotEmpty ? connection.other.name[0].toUpperCase() : 'A';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      leading: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE9A8), Color(0xFFFFC107), Color(0xFFF5B400)],
          ),
        ),
        alignment: Alignment.center,
        child: Text(initial,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
      ),
      title: Text(connection.other.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.ink)),
      subtitle: Text(connection.other.role ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
      trailing: IconButton(
        icon: const Icon(LucideIcons.messageCircle, color: AppColors.primaryDarker),
        tooltip: 'Message',
        onPressed: () async {
          final uid = int.tryParse(connection.other.id);
          if (uid == null) return;
          final (chatId, err) = await startConversationResult(ref, uid);
          if (!context.mounted) return;
          if (chatId != null) {
            context.push('/chat-screen', extra: {'id': chatId, 'name': connection.other.name, 'avatar': ''});
          } else {
            SnackBarUtils.showError(context, err ?? 'Could not open chat');
          }
        },
      ),
      onTap: () => context.push('/view-profile', extra: {'type': 'athlete', 'id': connection.other.id}),
      onLongPress: () => _confirmRemove(connection, currentUserId),
    );
  }

  void _confirmRemove(ConnectionRecord connection, String currentUserId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Connection'),
        content: Text('Remove ${connection.other.name} from your connections?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await removeConnection(ref, connection.id, currentUserId);
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Connection removed')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
