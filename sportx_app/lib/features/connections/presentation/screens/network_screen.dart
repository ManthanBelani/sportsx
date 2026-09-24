import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/athlete_directory_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/connections_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// v2 network.html — Network hub: "Grow your circle" + quick tiles
/// (Connections / Messages / Requests) + suggested people.
/// Reuses athleteDirectoryProvider + connectionStatusProvider; same
/// connect/message actions as the athlete directory.
class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen> {
  final Set<String> _busy = {};

  String _userIdOf(Map<String, dynamic> a) =>
      ((a['user'] as Map<String, dynamic>?)?['id'] ?? '').toString();

  String _nameOf(Map<String, dynamic> a) =>
      ((a['user'] as Map<String, dynamic>?)?['name'] ??
              a['full_name'] ??
              'Athlete')
          .toString();

  String? _photoOf(Map<String, dynamic> a) =>
      (a['photo'] as Map<String, dynamic>?)?['url']?.toString();

  String _subtitleOf(Map<String, dynamic> a) {
    final sports = (a['sports'] as List?)
            ?.map((s) => (s as Map)['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .join(', ') ??
        '';
    final city =
        (a['city'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
    return [
      if (sports.isNotEmpty) sports,
      if (city.isNotEmpty) city
    ].join(' • ');
  }

  Future<void> _connect(Map<String, dynamic> a) async {
    final uid = _userIdOf(a);
    if (uid.isEmpty) return;
    setState(() => _busy.add(uid));
    try {
      final err =
          await ref.read(athleteDirectoryProvider.notifier).connect(int.parse(uid));
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

  Future<void> _message(Map<String, dynamic> a) async {
    final uid = _userIdOf(a);
    if (uid.isEmpty) return;
    setState(() => _busy.add('m$uid'));
    try {
      final (chatId, err) =
          await startConversationResult(ref, int.parse(uid));
      if (!mounted) return;
      if (chatId != null) {
        context.push('/chat-screen', extra: {
          'id': chatId,
          'name': _nameOf(a),
          'avatar': _photoOf(a) ?? ''
        });
      } else {
        SnackBarUtils.showError(context, err ?? 'Could not start chat');
      }
    } finally {
      if (mounted) setState(() => _busy.remove('m$uid'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(athleteDirectoryProvider);
    final people = state.athletes.take(8).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Network',
            style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      ),
      body: RefreshIndicator(
        color: AppColors.yellowDeep,
        onRefresh: () =>
            ref.read(athleteDirectoryProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFFFFCF0)]),
                border: Border.all(color: const Color(0xFFF0E3B2)),
                borderRadius: BorderRadius.circular(18),
                boxShadow: SportXShadows.e1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grow your circle',
                      style: GoogleFonts.sora(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text('Coaches, scouts & athletes',
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _hubTile(
                              context,
                              label: 'Connections',
                              icon: LucideIcons.users,
                              tintBg: AppColors.infoLight,
                              tintFg: AppColors.info,
                              route: '/my-connections')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _hubTile(
                              context,
                              label: 'Messages',
                              icon: LucideIcons.messageCircle,
                              tintBg: const Color(0xFFDCFCE7),
                              tintFg: const Color(0xFF15803D),
                              route: '/chat-list')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _hubTile(
                              context,
                              label: 'Requests',
                              icon: LucideIcons.userPlus,
                              tintBg: AppColors.yellowTint,
                              tintFg: AppColors.warnText,
                              route: '/connection-requests')),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/sponsors'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: SportXShadows.e1,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.yellow),
                      alignment: Alignment.center,
                      child: const Icon(LucideIcons.briefcase,
                          size: 20, color: AppColors.ink),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Looking for funding?',
                              style: GoogleFonts.sora(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('Browse sponsors',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight,
                        color: Colors.white70, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(
                title: 'Suggested for you',
                actionText: 'See all',
                onActionTap: () => context.push('/athlete-directory')),
            if (state.isLoading && people.isEmpty)
              const GenericListSkeleton()
            else if (people.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text('No suggestions right now',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary))),
              )
            else
              for (final a in people) _personCard(a),
          ],
        ),
      ),
    );
  }

  Widget _hubTile(BuildContext context,
      {required String label,
      required IconData icon,
      required Color tintBg,
      required Color tintFg,
      required String route}) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: tintBg),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: tintFg),
            ),
            const SizedBox(height: 8),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
          ],
        ),
      ),
    );
  }

  Widget _personCard(Map<String, dynamic> a) {
    final uid = _userIdOf(a);
    final name = _nameOf(a);
    final subtitle = _subtitleOf(a);
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: SportXShadows.e1,
      ),
      child: Row(
        children: [
          AthleteAvatar(photoUrl: _photoOf(a), radius: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (uid.isEmpty)
            const SizedBox.shrink()
          else
            Consumer(builder: (context, ref, _) {
              final s = ref.watch(connectionStatusProvider(uid));
              return s.when(
                loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, _) => PrimaryButton(
                    label: 'Connect',
                    small: true,
                    onPressed: () => _connect(a)),
                data: (m) {
                  final st = m['status']?.toString() ?? 'none';
                  if (st == 'accepted') {
                    return SecondaryButton(
                        label: 'Message',
                        onPressed: () => _message(a));
                  }
                  if (st == 'pending') {
                    return const StatusPill(
                        label: 'Requested', kind: PillKind.pending);
                  }
                  final busy = _busy.contains(uid);
                  return PrimaryButton(
                      label: busy ? '…' : 'Connect',
                      small: true,
                      onPressed: busy ? null : () => _connect(a));
                },
              );
            }),
        ],
      ),
    );
  }
}
