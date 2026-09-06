import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_connection_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class TalentScoutConnectionScreen extends ConsumerStatefulWidget {
  final String athleteId;
  const TalentScoutConnectionScreen({super.key, required this.athleteId});

  @override
  ConsumerState<TalentScoutConnectionScreen> createState() => _TalentScoutConnectionScreenState();
}

class _TalentScoutConnectionScreenState extends ConsumerState<TalentScoutConnectionScreen> {
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    setState(() => _sending = true);
    try {
      final success = await ref.read(scoutConnectionProvider.notifier).sendConnectionRequest(
            widget.athleteId,
            message: _messageController.text.trim().isNotEmpty ? _messageController.text.trim() : null,
          );
      if (mounted) {
        if (success) {
          SnackBarUtils.showSuccess(context, 'Connection request sent');
          context.pop();
        } else {
          SnackBarUtils.showError(context, 'Failed to send connection request');
        }
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Send Connection Request',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Icon(LucideIcons.user, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Athlete',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('Connection request',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Message (optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write a message to the athlete...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _sending ? null : _sendRequest,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: _sending
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
