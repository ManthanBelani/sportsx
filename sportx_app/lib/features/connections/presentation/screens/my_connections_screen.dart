import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/connections_provider.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('My Connections',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        actions: [
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
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(myConnectionsProvider(currentUserId)),
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.textSecondary))),
                data: (_) => connections.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 200),
                        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(LucideIcons.users, size: 64, color: AppColors.textTertiary),
                          const SizedBox(height: 16),
                          Text('No connections yet', style: TextStyle(color: AppColors.textSecondary)),
                        ])),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: connections.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: const CircleAvatar(radius: 28, backgroundColor: AppColors.primary, child: Icon(LucideIcons.user, color: Colors.white)),
      title: Text(connection.other.name, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      subtitle: Text(connection.other.role ?? '', style: const TextStyle(color: AppColors.textSecondary)),
      trailing: IconButton(
        icon: const Icon(LucideIcons.messageCircle, color: AppColors.primary),
        onPressed: () => context.push('/chat-list'),
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
