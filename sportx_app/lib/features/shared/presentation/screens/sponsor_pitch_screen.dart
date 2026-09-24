import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/providers/activity_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class SponsorPitchScreen extends ConsumerStatefulWidget {
  final String sponsorId;
  const SponsorPitchScreen({super.key, required this.sponsorId});

  @override
  ConsumerState<SponsorPitchScreen> createState() => _SponsorPitchScreenState();
}

class _SponsorPitchScreenState extends ConsumerState<SponsorPitchScreen> {
  final _pitchController = TextEditingController();
  final _linkController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _pitchController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pitchController.text.trim().isEmpty) { SnackBarUtils.showError(context, 'Please write a pitch note before submitting'); return; }
    setState(() => _submitting = true);
    try {
      await ref.read(dioProvider).post('/sponsorships/${widget.sponsorId}/apply', data: {
        'pitch': _pitchController.text.trim(),
        'link': _linkController.text.trim(),
      });
      if (mounted) {
        ref.invalidate(activityProvider);
        SnackBarUtils.showSuccess(context, 'Application submitted!');
        context.push('/registration-confirmation');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e, 'Failed to submit pitch. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text('Apply for Sponsorship',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Your sport profile (achievements, media) will be automatically attached to this pitch.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Why are you a good fit?', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 12),
            TextField(
              controller: _pitchController,
              decoration: const InputDecoration(
                hintText: 'Write a cover letter / pitch note...',
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Additional Link (Optional)',
                hintText: 'e.g. YouTube highlight reel',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: AppColors.ink),
                child: _submitting
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Application'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
