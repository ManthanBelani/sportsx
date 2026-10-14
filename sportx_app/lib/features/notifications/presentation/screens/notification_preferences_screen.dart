import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/notifications/presentation/providers/notification_prefs_provider.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/theme/colors.dart';

/// Phase 9 prefs — account-action + registration rows are HARD OVERRIDES:
/// always in-app + email, rendered locked (not toggles that do nothing).
class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  static const _labels = {
    'people': 'People',
    'opportunities': 'Opportunities',
    'events': 'Events',
    'mentions': 'Mentions',
    'reminders': 'Reminders',
    'broadcasts': 'Broadcasts',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        elevation: 0,
        title: Text('Notification preferences',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: prefs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load preferences')),
        data: (p) => ListView(
          padding: const EdgeInsets.all(14),
          children: [
            SwitchListTile(
              title: const Text('Push notifications'),
              value: p.push,
              onChanged: (v) async {
                final ok = await updateNotificationPrefs(ref, push: v);
                if (!ok && context.mounted) SnackBarUtils.showError(context, 'Could not save');
              },
            ),
            const Divider(),
            ..._labels.entries.map((e) => SwitchListTile(
                  title: Text(e.value),
                  value: p.categories[e.key] ?? true,
                  onChanged: (v) async {
                    final ok = await updateNotificationPrefs(ref, categories: {e.key: v});
                    if (!ok && context.mounted) SnackBarUtils.showError(context, 'Could not save');
                  },
                )),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(LucideIcons.lock, size: 16, color: AppColors.primaryDarker),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Always on: account decisions + registration outcomes (in-app + email). These cannot be disabled.',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
