import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class RegistrantDetailScreen extends ConsumerWidget {
  final String registrationId;
  const RegistrantDetailScreen({super.key, required this.registrationId});

  Future<void> _act(BuildContext context, WidgetRef ref, String action, String msg) async {
    try {
      await ref.read(dioProvider).post('/registrations/trials/$registrationId/$action');
      if (context.mounted) {
        SnackBarUtils.showSuccess(context, msg);
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, e);
      }
    }
  }

  Future<void> _toggleReminder(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(dioProvider).post('/registrations/trials/$registrationId/reminder');
      if (context.mounted) SnackBarUtils.showSuccess(context, 'Reminder toggled');
    } catch (e) {
      if (context.mounted) SnackBarUtils.showError(context, e);
    }
  }

  Future<void> _downloadIcs(BuildContext context, WidgetRef ref) async {
    try {
      final resp = await ref.read(dioProvider).get('/registrations/trials/$registrationId/ics');
      final ics = resp.data is String ? resp.data as String : resp.data.toString();
      if (context.mounted) SnackBarUtils.showSuccess(context, 'ICS ready (${ics.length} bytes)');
      // In prod, write to temp file + share via share_plus
    } catch (e) {
      if (context.mounted) SnackBarUtils.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Registrant',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registration #$registrationId',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _toggleReminder(context, ref), icon: const Icon(LucideIcons.bell, size: 16), label: const Text('Toggle Reminder'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: () => _downloadIcs(context, ref), icon: const Icon(LucideIcons.calendar, size: 16), label: const Text('Download ICS'))),
            ]),
            const SizedBox(height: 32),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _act(context, ref, 'reject', 'Registration Rejected.'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _act(context, ref, 'verify', 'Marked as Verified.'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                    child: const Text('Mark as Verified'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
