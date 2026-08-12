import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class AcademyProfilePostingScreen extends ConsumerStatefulWidget {
  const AcademyProfilePostingScreen({super.key});

  @override
  ConsumerState<AcademyProfilePostingScreen> createState() => _AcademyProfilePostingScreenState();
}

class _AcademyProfilePostingScreenState extends ConsumerState<AcademyProfilePostingScreen> {
  final _name = TextEditingController();
  final _sport = TextEditingController();
  final _facilities = TextEditingController();
  final _fee = TextEditingController();
  final _ageGroups = TextEditingController();
  final _timings = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final academy = ref.read(myAcademyProvider).valueOrNull;
    if (academy != null) {
      _name.text = academy.name;
      _sport.text = academy.sport?.name ?? '';
      _fee.text = academy.monthlyRate?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _sport.dispose();
    _facilities.dispose();
    _fee.dispose();
    _ageGroups.dispose();
    _timings.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).put('/me/academy', data: {
        'name': _name.text.trim(),
        'sport': _sport.text.trim(),
        'facilities': _facilities.text.trim(),
        'monthly_rate': num.tryParse(_fee.text.trim()) ?? 0,
        'age_groups': _ageGroups.text.trim(),
        'timings': _timings.text.trim(),
      });
      ref.invalidate(myAcademyProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Academy Updated!')));
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
        title: const Text('Edit Academy Listing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 16),
            TextField(controller: _sport, decoration: const InputDecoration(labelText: 'Sport(s)')),
            const SizedBox(height: 16),
            TextField(controller: _facilities, decoration: const InputDecoration(labelText: 'Facilities')),
            const SizedBox(height: 16),
            TextField(controller: _fee, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Fee')),
            const SizedBox(height: 16),
            TextField(controller: _ageGroups, decoration: const InputDecoration(labelText: 'Age Groups')),
            const SizedBox(height: 16),
            TextField(controller: _timings, decoration: const InputDecoration(labelText: 'Timings')),
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
