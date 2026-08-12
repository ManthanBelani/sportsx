import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/connections_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class ConnectionRequestsScreen extends ConsumerStatefulWidget {
  const ConnectionRequestsScreen({super.key});

  @override
  ConsumerState<ConnectionRequestsScreen> createState() => _ConnectionRequestsScreenState();
}

class _ConnectionRequestsScreenState extends ConsumerState<ConnectionRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider).user?.id.toString() ?? '';
    final async = ref.watch(connectionRequestsProvider(currentUserId));
    final requests = async.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Connection Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Received (${requests.length})'),
            const Tab(text: 'Sent'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(connectionRequestsProvider(currentUserId)),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.textSecondary))),
          data: (_) => TabBarView(
            controller: _tabController,
            children: [
              _buildReceivedTab(requests, currentUserId),
              const Center(child: Text('Sent requests are not exposed by the API yet',
                  style: TextStyle(color: AppColors.textSecondary))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedTab(List<ConnectionRecord> requests, String currentUserId) {
    if (requests.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 200),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.inbox, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('No pending requests', style: TextStyle(color: AppColors.textSecondary)),
        ])),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) => _buildRequestCard(requests[index], currentUserId),
    );
  }

  Widget _buildRequestCard(ConnectionRecord request, String currentUserId) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 28, backgroundColor: AppColors.primary, child: Icon(LucideIcons.user, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(request.other.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _actions(request, currentUserId),
          ],
        ),
      ),
    );
  }

  Widget _actions(ConnectionRecord request, String currentUserId) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              await removeConnection(ref, request.id, currentUserId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request from ${request.other.name} declined')));
              }
            },
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: const Text('Decline'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              await acceptConnection(ref, request.id, currentUserId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connected with ${request.other.name}')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Accept'),
          ),
        ),
      ],
    );
  }
}
