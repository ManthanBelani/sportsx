import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_connection_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
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
  Map<String, dynamic>? _athlete;
  bool _loadingAthlete = true;

  @override
  void initState() {
    super.initState();
    _loadAthlete();
  }

  Future<void> _loadAthlete() async {
    try {
      final resp = await ref.read(dioProvider).get('/athletes/${widget.athleteId}');
      final data = resp.data is Map && resp.data['data'] is Map ? resp.data['data'] as Map<String, dynamic> : resp.data as Map<String, dynamic>;
      if (mounted) setState(() { _athlete = data; _loadingAthlete = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingAthlete = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    if (_messageController.text.trim().length > 1000) {
      SnackBarUtils.showError(context, 'Message too long (max 1000)');
      return;
    }
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
          final err = ref.read(scoutConnectionProvider).error;
          if (err != null && err.toLowerCase().contains('already')) {
            SnackBarUtils.showError(context, 'Connection already exists');
          } else {
            SnackBarUtils.showError(context, err ?? 'Failed to send connection request');
          }
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
    final name = _athlete?['user']?['name'] ?? _athlete?['full_name'] ?? 'Athlete';
    final photoUrl = _athlete?['photo']?['url'] as String? ?? _athlete?['photo_url'] as String?;
    final sport = (_athlete?['sports'] is List && (_athlete!['sports'] as List).isNotEmpty)
        ? (_athlete!['sports'][0]['name'] ?? '').toString()
        : '';
    final city = _athlete?['city']?['name']?.toString();

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
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _loadingAthlete
                      ? const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      : AthleteAvatar(photoUrl: photoUrl, radius: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          [sport, if (city != null) city].where((e) => e.isNotEmpty).join(' • ').isEmpty ? 'Connection request' : [sport, if (city != null) city].where((e) => e.isNotEmpty).join(' • '),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('A personal message increases acceptance rate', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            const Text('Message (optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Hi! I\'m a talent scout with ${_athlete?['city']?['name'] ?? 'your region'}... I noticed your performance in... Would love to connect.',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
                contentPadding: const EdgeInsets.all(14),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _sending ? null : _sendRequest,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _sending
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Request', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
