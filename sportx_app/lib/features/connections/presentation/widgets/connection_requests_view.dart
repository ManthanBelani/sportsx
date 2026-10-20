import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/connections_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/scout_requests_provider.dart';
import 'package:sportx_app/features/connections/presentation/widgets/scout_requests_view.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';

/// Connection requests content, usable standalone (inside a Scaffold) or
/// embedded as an inner tab (e.g. the "Requests" tab of the Messages screen).
///
/// The widget owns its own Received/Scout/Sent switcher so it can be dropped
/// into any parent without needing a [TabController] from the host.
class ConnectionRequestsView extends ConsumerStatefulWidget {
  const ConnectionRequestsView({super.key});

  @override
  ConsumerState<ConnectionRequestsView> createState() => _ConnectionRequestsViewState();
}

class _ConnectionRequestsViewState extends ConsumerState<ConnectionRequestsView> {
  int _tab = 0; // 0 = Received, 1 = Scout, 2 = Sent

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final currentUserId = user?.id.toString() ?? '';
    final async = ref.watch(connectionRequestsProvider(currentUserId));
    final requests = async.valueOrNull ?? [];
    // Scout requests are an athlete-only inbox (GET /me/scout-connection-requests).
    final showScout = user?.role == 'athlete';
    final scoutState = ref.watch(scoutRequestsProvider);
    final scoutCount = scoutState.requests.length;

    final tabs = <String>[
      'Received${requests.isEmpty ? '' : ' (${requests.length})'}',
      if (showScout) 'Scout${scoutCount == 0 ? '' : ' ($scoutCount)'}',
      'Sent',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _tabChip(tabs[i], i),
              ],
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(connectionRequestsProvider(currentUserId));
              await ref.read(scoutRequestsProvider.notifier).load();
            },
            child: async.when(
              loading: () => const ConnectionsSkeleton(),
              error: (e, _) => Center(
                child: Text(ApiException.messageFor(e), style: const TextStyle(color: AppColors.textSecondary)),
              ),
              data: (_) => _tab == 0
                  ? _buildReceivedTab(requests, currentUserId)
                  : _tab == 1 && showScout
                      ? const ScoutRequestsView()
                      : const Center(
                          child: Text(
                            'Sent requests are not exposed by the API yet',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabChip(String label, int i) {
    final active = _tab == i;
    return GestureDetector(
      onTap: () => setState(() => _tab = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [Color(0xFFFFD54A), Color(0xFFFFC107), Color(0xFFF5B400)])
              : null,
          color: active ? null : Colors.white,
          border: Border.all(color: active ? const Color(0x2E785000) : AppColors.border),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: AppColors.ink)),
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
