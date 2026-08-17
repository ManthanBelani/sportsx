import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class SponsorOnboardingScreen extends ConsumerStatefulWidget {
  const SponsorOnboardingScreen({super.key});

  @override
  ConsumerState<SponsorOnboardingScreen> createState() => _SponsorOnboardingScreenState();
}

class _SponsorOnboardingScreenState extends ConsumerState<SponsorOnboardingScreen> {
  final _brand = TextEditingController();
  String _category = 'sportswear';
  bool _saving = false;

  @override
  void dispose() {
    _brand.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).post('/onboarding/sponsor', data: {
        'brand_name': _brand.text.trim(),
        'category': _category,
      });
      if (mounted) {
        ref.read(authProvider.notifier).markOnboardingComplete();
        await ref.read(authProvider.notifier).refreshUser();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Submitted for Review')));
        context.go('/sponsor-dashboard');
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
        title: const Text('Set up your brand profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _brand, decoration: const InputDecoration(labelText: 'Brand Name')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'sportswear', child: Text('Sportswear')),
                DropdownMenuItem(value: 'energy_drink', child: Text('Energy Drink')),
                DropdownMenuItem(value: 'equipment', child: Text('Equipment')),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
