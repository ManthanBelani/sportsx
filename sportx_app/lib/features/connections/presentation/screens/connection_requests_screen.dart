import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/connections_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/scout_requests_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text('Connection Requests',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
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
      body: Column(
        children: [
          _scoutRequestsEntry(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(connectionRequestsProvider(currentUserId));
                await ref.read(scoutRequestsProvider.notifier).load();
              },
              child: async.when(
                loading: () => const ConnectionsSkeleton(),
                error: (e, _) => Center(child: Text(ApiException.messageFor(e), style: TextStyle(color: AppColors.textSecondary))),
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
          ),
        ],
      ),
    );
  }

  /// Entry to the talent-scout inbox. Scouts connect through a separate flow
  /// (scout_connections), so their requests don't appear in the tabs below.
  Widget _scoutRequestsEntry() {
    final pending = ref.watch(scoutRequestsProvider).pendingCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () => context.push('/scout-requests'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: SportXShadows.e1,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.userSearch, size: 20, color: AppColors.scout),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scout Requests',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(
                      pending > 0 ? '$pending pending request${pending == 1 ? '' : 's'} from talent scouts' : 'Requests from talent scouts appear here',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (pending > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(999)),
                  child: Text('$pending',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                )
              else
                const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
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
          Text('No pending requests', style: GoogleFonts.inter(color: AppColors.textSecondary)),
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
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _avatar(request.other.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(request.other.name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.ink)),
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

  Widget _avatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return Container(
      width: 56,
      height: 56,
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
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
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
                SnackBarUtils.showSuccess(context, 'Request from ${request.other.name} declined');
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
                SnackBarUtils.showSuccess(context, 'Connected with ${request.other.name}');
              }
            },
            child: const Text('Accept'),
          ),
        ),
      ],
    );
  }
}
