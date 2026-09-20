import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/connections/presentation/providers/scout_requests_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';

/// Athlete inbox for incoming talent-scout connection requests.
/// Requests arrive here when a scout taps Connect on the athlete's profile
/// (the athlete also gets a notification pointing at this screen).
class ScoutRequestsScreen extends ConsumerStatefulWidget {
  const ScoutRequestsScreen({super.key});

  @override
  ConsumerState<ScoutRequestsScreen> createState() => _ScoutRequestsScreenState();
}

class _ScoutRequestsScreenState extends ConsumerState<ScoutRequestsScreen> {
  final Set<String> _acting = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(scoutRequestsProvider.notifier).load());
  }

  Future<void> _respond(String id, String name, bool accept) async {
    setState(() => _acting.add(id));
    try {
      final ok = accept
          ? await ref.read(scoutRequestsProvider.notifier).accept(id)
          : await ref.read(scoutRequestsProvider.notifier).reject(id);
      if (mounted) {
        if (ok) {
          SnackBarUtils.showSuccess(
              context, accept ? 'Connected with $name' : 'Request declined');
        } else {
          SnackBarUtils.showError(
              context, ref.read(scoutRequestsProvider).error ?? 'Something went wrong');
        }
      }
    } finally {
      if (mounted) setState(() => _acting.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scoutRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Scout Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.pop()),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border)),
      ),
      body: state.isLoading && state.requests.isEmpty
          ? const ConnectionsSkeleton()
          : state.error != null && state.requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.border),
                      const SizedBox(height: 16),
                      Text(state.error!,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.read(scoutRequestsProvider.notifier).load(),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.requests.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.userSearch, size: 48, color: AppColors.border),
                          SizedBox(height: 16),
                          Text('No scout requests yet',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                          SizedBox(height: 8),
                          Text('When a talent scout reaches out, it will appear here',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(scoutRequestsProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.requests.length,
                        itemBuilder: (context, index) =>
                            _buildRequestCard(state.requests[index]),
                      ),
                    ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final scout = req['scout'] as Map<String, dynamic>?;
    final scoutUser = scout?['user'] as Map<String, dynamic>?;
    final photoUrl = (scout?['photo'] as Map<String, dynamic>?)?['url'] as String?;
    final name = scoutUser?['name']?.toString() ?? 'Talent Scout';
    final org = scout?['organization']?.toString();
    final affiliation = scout?['affiliation']?.toString();
    final city = (scout?['city'] as Map<String, dynamic>?)?['name']?.toString();
    final exp = scout?['experience_years'];
    final message = req['message']?.toString();
    final status = (req['status'] ?? 'pending').toString();
    final id = req['id'].toString();
    final busy = _acting.contains(id);

    final subtitle = [
      if (org != null && org.isNotEmpty) org,
      if (city != null && city.isNotEmpty) city,
      if (exp != null) '$exp yrs exp',
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AthleteAvatar(photoUrl: photoUrl, radius: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                  if (affiliation != null && affiliation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(affiliation,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ]),
              ),
              _statusBadge(status),
            ],
          ),
          if (message != null && message.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('"$message"',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
            ),
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _respond(id, name, false),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : () => _respond(id, name, true),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    child: busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'accepted':
        bg = const Color(0xFFd1fae5);
        fg = const Color(0xFF065f46);
        break;
      case 'rejected':
        bg = const Color(0xFFfee2e2);
        fg = const Color(0xFF991b1b);
        break;
      default:
        bg = const Color(0xFFfef3c7);
        fg = const Color(0xFF92400e);
    }
    final label = status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
