import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class TrialPostingScreen extends ConsumerStatefulWidget {
  const TrialPostingScreen({super.key});

  @override
  ConsumerState<TrialPostingScreen> createState() => _TrialPostingScreenState();
}

class _TrialPostingScreenState extends ConsumerState<TrialPostingScreen> {
  final _name = TextEditingController();
  final _sport = TextEditingController();
  final _date = TextEditingController();
  final _venue = TextEditingController();
  final _eligibility = TextEditingController();
  final _fee = TextEditingController();
  final _docs = TextEditingController();
  final _contact = TextEditingController();
  bool _publish = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _sport.dispose();
    _date.dispose();
    _venue.dispose();
    _eligibility.dispose();
    _fee.dispose();
    _docs.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await ref.read(providerTrialActionsProvider).create({
      'title': _name.text.trim(),
      'sport': _sport.text.trim(),
      'trial_date': _date.text.trim(),
      'venue': _venue.text.trim(),
      'eligibility': _eligibility.text.trim(),
      'registration_fee': num.tryParse(_fee.text.trim()) ?? 0,
      'document_required': _docs.text.trim(),
      'contact_number': _contact.text.trim(),
      'status': _publish ? 'published' : 'draft',
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_publish ? 'Trial Published!' : 'Draft saved')));
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
        title: const Text('Post a New Trial',
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
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Trial Name', hintText: 'e.g. U-14 Cricket Trial')),
            const SizedBox(height: 16),
            TextField(controller: _sport, decoration: const InputDecoration(labelText: 'Sport')),
            const SizedBox(height: 16),
            TextField(controller: _date, decoration: const InputDecoration(labelText: 'Date & Time', hintText: 'YYYY-MM-DD')),
            const SizedBox(height: 16),
            TextField(controller: _venue, decoration: const InputDecoration(labelText: 'Venue')),
            const SizedBox(height: 16),
            TextField(controller: _eligibility, decoration: const InputDecoration(labelText: 'Eligibility', hintText: 'e.g. Boys, U-14')),
            const SizedBox(height: 16),
            TextField(controller: _fee, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Entry Fee', hintText: '₹200')),
            const SizedBox(height: 16),
            TextField(controller: _docs, decoration: const InputDecoration(labelText: 'Required Docs', hintText: 'e.g. Aadhaar, Photo')),
            const SizedBox(height: 16),
            TextField(controller: _contact, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact Number')),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Radio(value: false, groupValue: _publish, onChanged: (v) => setState(() => _publish = v ?? false)),
                const Text('Draft'),
                Radio(value: true, groupValue: _publish, onChanged: (v) => setState(() => _publish = v ?? true)),
                const Text('Published'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_publish ? 'Save & Publish' : 'Save Draft'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
