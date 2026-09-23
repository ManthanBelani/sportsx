import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/athlete_directory_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/connections_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';

/// Athlete-to-athlete discovery: find peers, connect, and chat.
/// Chat unlocks after the connection is accepted (backend 403 CONNECTION_REQUIRED otherwise).
class AthleteDirectoryScreen extends ConsumerStatefulWidget {
  const AthleteDirectoryScreen({super.key});

  @override
  ConsumerState<AthleteDirectoryScreen> createState() => _AthleteDirectoryScreenState();
}

class _AthleteDirectoryScreenState extends ConsumerState<AthleteDirectoryScreen> {
  final _search = TextEditingController();
  final Set<String> _busy = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _userIdOf(Map<String, dynamic> a) =>
      ((a['user'] as Map<String, dynamic>?)?['id'] ?? '').toString();

  String _nameOf(Map<String, dynamic> a) =>
      ((a['user'] as Map<String, dynamic>?)?['name'] ?? a['full_name'] ?? 'Athlete').toString();

  String? _photoOf(Map<String, dynamic> a) =>
      (a['photo'] as Map<String, dynamic>?)?['url']?.toString();

  Future<void> _message(Map<String, dynamic> a) async {
    final uid = _userIdOf(a);
    if (uid.isEmpty) return;
    setState(() => _busy.add('m$uid'));
    try {
      final (chatId, err) = await startConversationResult(ref, int.parse(uid));
      if (!mounted) return;
      if (chatId != null) {
        context.push('/chat-screen', extra: {'id': chatId, 'name': _nameOf(a), 'avatar': _photoOf(a) ?? ''});
      } else {
        SnackBarUtils.showError(context, err ?? 'Could not open chat');
      }
    } finally {
      if (mounted) setState(() => _busy.remove('m$uid'));
    }
  }

  Future<void> _connect(Map<String, dynamic> a) async {
    final uid = _userIdOf(a);
    if (uid.isEmpty) return;
    setState(() => _busy.add(uid));
    try {
      final err = await ref.read(athleteDirectoryProvider.notifier).connect(int.parse(uid));
      if (!mounted) return;
      if (err == null) {
        SnackBarUtils.showSuccess(context, 'Request sent to ${_nameOf(a)}');
        ref.invalidate(connectionStatusProvider(uid));
      } else {
        SnackBarUtils.showError(context, err);
      }
    } finally {
      if (mounted) setState(() => _busy.remove(uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(athleteDirectoryProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Find Athletes',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        actions: [
          IconButton(icon: const Icon(LucideIcons.userPlus, color: AppColors.textPrimary), tooltip: 'Requests', onPressed: () => context.push('/connection-requests')),
          IconButton(icon: const Icon(LucideIcons.messageCircle, color: AppColors.textPrimary), tooltip: 'Chats', onPressed: () => context.push('/chat-list')),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => ref.read(athleteDirectoryProvider.notifier).load(query: v.trim()),
            decoration: InputDecoration(
              hintText: 'Search athletes by name…',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              suffixIcon: IconButton(icon: const Icon(LucideIcons.x, size: 16), onPressed: () {
                _search.clear();
                ref.read(athleteDirectoryProvider.notifier).load();
              }),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        Expanded(
          child: state.isLoading && state.athletes.isEmpty
              ? const GenericListSkeleton()
              : state.error != null && state.athletes.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.border),
                      const SizedBox(height: 12),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text(state.error!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: () => ref.read(athleteDirectoryProvider.notifier).load(), style: FilledButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: AppColors.ink), child: const Text('Retry')),
                    ]))
                  : state.athletes.isEmpty
                      ? const Center(child: Text('No athletes found', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)))
                      : RefreshIndicator(
                          onRefresh: () => ref.read(athleteDirectoryProvider.notifier).load(query: _search.text.trim()),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: state.athletes.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, i) => _card(state.athletes[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _card(Map<String, dynamic> a) {
    final uid = _userIdOf(a);
    final name = _nameOf(a);
    final photoUrl = _photoOf(a);
    final sports = (a['sports'] as List?)?.map((s) => (s as Map)['name']?.toString() ?? '').where((s) => s.isNotEmpty).join(', ') ?? '';
    final city = (a['city'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
    final subtitle = [if (sports.isNotEmpty) sports, if (city.isNotEmpty) city].join(' • ');
    final profileId = (a['id'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: profileId.isEmpty ? null : () => context.push('/view-profile', extra: {'type': 'athlete', 'id': profileId}),
          child: Row(children: [
            AthleteAvatar(photoUrl: photoUrl, radius: 26),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (subtitle.isNotEmpty) ...[const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)],
            ])),
          ]),
        ),
        const SizedBox(height: 12),
        if (uid.isEmpty)
          const SizedBox.shrink()
        else
          Consumer(builder: (context, ref, _) {
            final statusAsync = ref.watch(connectionStatusProvider(uid));
            return statusAsync.when(
              loading: () => const SizedBox(height: 36, child: Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)))),
              error: (_, _) => _connectButton(uid, null, athlete: a),
              data: (s) => _connectButton(uid, s['status']?.toString() ?? 'none', isInitiator: s['is_initiator'] == true, athlete: a),
            );
          }),
      ]),
    );
  }

  Widget _connectButton(String uid, String? status, {bool isInitiator = true, Map<String, dynamic>? athlete}) {
    final busy = _busy.contains(uid) || _busy.contains('m$uid');
    if (athlete == null) return const SizedBox.shrink();
    if (status == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: busy ? null : () => _message(athlete!),
          icon: const Icon(LucideIcons.messageCircle, size: 16),
          label: const Text('Message'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
        ),
      );
    }
    if (status == 'pending') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: null,
          child: Text(isInitiator ? 'Request Sent' : 'Respond in Requests'),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : () => _connect(athlete!),
        style: FilledButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: AppColors.ink),
        child: busy
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Connect'),
      ),
    );
  }
}
