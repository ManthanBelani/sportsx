import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/sponsor/presentation/providers/sponsor_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class SponsorshipPostingScreen extends ConsumerStatefulWidget {
  const SponsorshipPostingScreen({super.key});

  @override
  ConsumerState<SponsorshipPostingScreen> createState() => _SponsorshipPostingScreenState();
}

class _SponsorshipPostingScreenState extends ConsumerState<SponsorshipPostingScreen> {
  final _title = TextEditingController();
  final _sport = TextEditingController();
  final _eligibility = TextEditingController();
  final _benefits = TextEditingController();
  final _deadline = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _sport.dispose();
    _eligibility.dispose();
    _benefits.dispose();
    _deadline.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await ref.read(sponsorshipActionsProvider).create({
      'title': _title.text.trim(),
      'sport': _sport.text.trim(),
      'eligibility': _eligibility.text.trim(),
      'benefits': _benefits.text.trim(),
      'application_deadline': _deadline.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sponsorship saved!')));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Create Sponsorship',
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
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. U-16 Cricket Kit')),
            const SizedBox(height: 16),
            TextField(controller: _sport, decoration: const InputDecoration(labelText: 'Sport')),
            const SizedBox(height: 16),
            TextField(controller: _eligibility, decoration: const InputDecoration(labelText: 'Eligibility', hintText: 'State-level players only')),
            const SizedBox(height: 16),
            TextField(
              controller: _benefits,
              decoration: const InputDecoration(labelText: 'Benefits Offered', hintText: 'Free kit + ₹5000 stipend / month'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(controller: _deadline, decoration: const InputDecoration(labelText: 'Deadline', hintText: 'YYYY-MM-DD')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save & Publish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
