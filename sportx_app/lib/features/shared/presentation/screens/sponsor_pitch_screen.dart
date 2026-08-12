import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';

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
    if (_pitchController.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(dioProvider).post('/sponsorships/${widget.sponsorId}/apply', data: {
        'pitch': _pitchController.text.trim(),
        'link': _linkController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted!')));
        context.push('/registration-confirmation');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Apply for Sponsorship',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
            Text('Why are you a good fit?', style: Theme.of(context).textTheme.titleMedium),
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
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
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
