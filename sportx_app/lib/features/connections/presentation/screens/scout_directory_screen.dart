import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/scout_directory_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';

/// Athlete discovers talent scouts and connects (two-way connect).
/// After accept, the [Message] button opens /chat-screen via POST /me/conversations.
class ScoutDirectoryScreen extends ConsumerStatefulWidget {
  const ScoutDirectoryScreen({super.key});

  @override
  ConsumerState<ScoutDirectoryScreen> createState() => _ScoutDirectoryScreenState();
}

class _ScoutDirectoryScreenState extends ConsumerState<ScoutDirectoryScreen> {
  final _search = TextEditingController();
  final Set<String> _busy = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _message(Map<String, dynamic> scout, String name, String? photoUrl) async {
    final user = scout['user'] as Map<String, dynamic>?;
    final userId = user?['id'];
    if (userId == null) {
      SnackBarUtils.showError(context, 'Scout user not found');
      return;
    }
    setState(() => _busy.add('m${scout['id']}'));
    try {
      final (chatId, err) = await startConversationResult(ref, int.parse(userId.toString()));
      if (!mounted) return;
      if (chatId != null) {
        context.push('/chat-screen', extra: {'id': chatId, 'name': name, 'avatar': photoUrl ?? ''});
      } else {
        SnackBarUtils.showError(context, err ?? 'Could not open chat');
      }
    } finally {
      if (mounted) setState(() => _busy.remove('m${scout['id']}'));
    }
  }

  Future<void> _connect(Map<String, dynamic> scout, String name) async {
    final id = scout['id'].toString();
    setState(() => _busy.add(id));
    try {
      final ok = await ref.read(scoutDirectoryProvider.notifier).connect(id);
      if (mounted) {
        SnackBarUtils.showSuccess(context, ok ? 'Request sent to $name' : ref.read(scoutDirectoryProvider).error ?? 'Failed to connect');
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scoutDirectoryProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Find Scouts',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        actions: [
          IconButton(icon: const Icon(LucideIcons.mail, color: AppColors.textPrimary), tooltip: 'Scout requests', onPressed: () => context.push('/scout-requests')),
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
            onSubmitted: (v) => ref.read(scoutDirectoryProvider.notifier).load(query: v.trim()),
            decoration: InputDecoration(
              hintText: 'Search by name, organization…',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              suffixIcon: IconButton(icon: const Icon(LucideIcons.x, size: 16), onPressed: () {
                _search.clear();
                ref.read(scoutDirectoryProvider.notifier).load();
              }),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        Expanded(
          child: state.isLoading && state.scouts.isEmpty
              ? const GenericListSkeleton()
              : state.error != null && state.scouts.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.border),
                      const SizedBox(height: 12),
                      Text(state.error!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: () => ref.read(scoutDirectoryProvider.notifier).load(), style: FilledButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: AppColors.ink), child: const Text('Retry')),
                    ]))
                  : state.scouts.isEmpty
                      ? const Center(child: Text('No scouts found', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)))
                      : RefreshIndicator(
                          onRefresh: () => ref.read(scoutDirectoryProvider.notifier).load(query: _search.text.trim()),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: state.scouts.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, i) => _card(state.scouts[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _card(Map<String, dynamic> scout) {
    final user = scout['user'] as Map<String, dynamic>?;
    final name = user?['name']?.toString() ?? 'Talent Scout';
    final photoUrl = (scout['photo'] as Map<String, dynamic>?)?['url']?.toString();
    final org = scout['organization']?.toString() ?? '';
    final city = (scout['city'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
    final exp = scout['experience_years'];
    final connStatus = (scout['connection_status'] as String?) ?? _inferStatus(scout);
    final busy = _busy.contains(scout['id'].toString());

    final subtitle = [if (org.isNotEmpty) org, if (city.isNotEmpty) city, if (exp != null) '$exp yrs exp'].join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AthleteAvatar(photoUrl: photoUrl, radius: 26),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            if (subtitle.isNotEmpty) ...[const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))],
          ])),
          _badge(connStatus),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          if (connStatus == 'accepted')
            Expanded(child: OutlinedButton.icon(
              onPressed: _busy.contains('m${scout['id']}') ? null : () => _message(scout, name, photoUrl),
              icon: const Icon(LucideIcons.messageCircle, size: 16),
              label: const Text('Message'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
            ))
          else if (connStatus == 'pending')
            const Expanded(child: OutlinedButton(onPressed: null, child: Text('Request Sent')))
          else
            Expanded(child: FilledButton(
              onPressed: busy ? null : () => _connect(scout, name),
              style: FilledButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: AppColors.ink),
              child: busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Connect'),
            )),
        ]),
      ]),
    );
  }

  String? _inferStatus(Map<String, dynamic> scout) {
    // Fallback when backend did not attach connection_status.
    return scout['connection_id'] != null ? 'pending' : null;
  }

  Widget _badge(String? status) {
    if (status == null) return const SizedBox.shrink();
    Color bg;
    Color fg;
    switch (status) {
      case 'accepted':
        bg = AppColors.successLight;
        fg = AppColors.success;
        break;
      case 'rejected':
        bg = AppColors.errorLight;
        fg = AppColors.error;
        break;
      default:
        bg = AppColors.yellowTint;
        fg = AppColors.warnText;
    }
    final label = status[0].toUpperCase() + status.substring(1);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)));
  }
}
