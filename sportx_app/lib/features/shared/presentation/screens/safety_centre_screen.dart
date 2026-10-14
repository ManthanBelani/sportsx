import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/connections/presentation/providers/follow_block_provider.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/theme/colors.dart';

/// v3 S.23 Safety Centre — blocked users + my reports.
/// v3 tokens: yellow gradient CTA, white cards on surface, Sora titles.
class SafetyCentreScreen extends ConsumerWidget {
  const SafetyCentreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedUsersProvider);
    final reports = ref.watch(myReportsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        elevation: 0,
        title: Text('Safety Centre',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(blockedUsersProvider);
          ref.invalidate(myReportsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _sectionTitle('Blocked users'),
            blocked.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
              error: (e, _) => _empty('Could not load blocked users. Pull to retry.'),
              data: (rows) => rows.isEmpty
                  ? _empty('No blocked users. Blocking hides content both ways and disables chat.')
                  : Column(
                      children: rows.map((r) {
                        final u = r['blocked'] as Map<String, dynamic>?;
                        final name = (u?['name'] ?? 'User').toString();
                        final id = (u?['id'] ?? r['blocked_user_id']).toString();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(14)),
                          child: Row(children: [
                            const Icon(LucideIcons.shieldOff, color: AppColors.textSecondary),
                            const SizedBox(width: 10),
                            Expanded(child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                            TextButton(
                              onPressed: () async {
                                final ok = await unblockUser(ref, id);
                                if (context.mounted) {
                                  if (ok) {
                                    SnackBarUtils.showSuccess(context, 'Unblocked $name');
                                  } else {
                                    SnackBarUtils.showError(context, 'Could not unblock');
                                  }
                                }
                              },
                              child: const Text('Unblock'),
                            ),
                          ]),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),
            _sectionTitle('My reports'),
            reports.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
              error: (e, _) => _empty('Could not load reports.'),
              data: (rows) => rows.isEmpty
                  ? _empty('No reports yet. Every post, listing and profile can be reported.')
                  : Column(
                      children: rows.map((r) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(14)),
                          child: Row(children: [
                            const Icon(LucideIcons.flag, color: AppColors.primaryDarker),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${r['reportable_type']} #${r['reportable_id']}',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('${r['reason']} • ${r['status'] ?? 'pending'}',
                                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                              ]),
                            ),
                          ]),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
        child: Text(t, style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
      );

  Widget _empty(String t) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
        child: Text(t, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
      );
}
