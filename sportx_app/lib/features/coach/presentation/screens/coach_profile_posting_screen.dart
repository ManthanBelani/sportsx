import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';

class CoachProfilePostingScreen extends ConsumerStatefulWidget {
  const CoachProfilePostingScreen({super.key});

  @override
  ConsumerState<CoachProfilePostingScreen> createState() => _CoachProfilePostingScreenState();
}

class _CoachProfilePostingScreenState extends ConsumerState<CoachProfilePostingScreen> {
  final _name = TextEditingController();
  final _sport = TextEditingController();
  final _experience = TextEditingController();
  final _fee = TextEditingController();
  final _location = TextEditingController();
  final _bio = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _sport.dispose();
    _experience.dispose();
    _fee.dispose();
    _location.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).put('/me/coach-profile', data: {
        'full_name': _name.text.trim(),
        'sport': _sport.text.trim(),
        'experience': int.tryParse(_experience.text.trim()) ?? 0,
        'hourly_rate': num.tryParse(_fee.text.trim()) ?? 0,
        'city': _location.text.trim(),
        'bio': _bio.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Edit My Listing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 16),
            TextField(controller: _sport, decoration: const InputDecoration(labelText: 'Sport(s)')),
            const SizedBox(height: 16),
            TextField(controller: _experience, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Experience (years)')),
            const SizedBox(height: 16),
            TextField(controller: _fee, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fee per session')),
            const SizedBox(height: 16),
            TextField(controller: _location, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 16),
            TextField(controller: _bio, decoration: const InputDecoration(labelText: 'Bio'), maxLines: 4),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
