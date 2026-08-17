import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class CoachOnboardingScreen extends ConsumerStatefulWidget {
  const CoachOnboardingScreen({super.key});

  @override
  ConsumerState<CoachOnboardingScreen> createState() => _CoachOnboardingScreenState();
}

class _CoachOnboardingScreenState extends ConsumerState<CoachOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _experience = TextEditingController();
  final _qualification = TextEditingController();
  final _fee = TextEditingController();
  int? _sportId;
  int? _cityId;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _experience.dispose();
    _qualification.dispose();
    _fee.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_sportId == null || _cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select sport and city')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).post('/onboarding/coach', data: {
        'full_name': _name.text.trim(),
        'sport_id': _sportId,
        'city_id': _cityId,
        'contact_number': _contact.text.trim(),
        'experience': _experience.text.trim(),
        if (_qualification.text.trim().isNotEmpty) 'qualification': _qualification.text.trim(),
        if (_fee.text.trim().isNotEmpty) 'fee_structure': _fee.text.trim(),
      });
      ref.read(authProvider.notifier).markOnboardingComplete();
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) context.go('/coach-dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 24),
          onPressed: () => context.pop(),
        ),
        title: const Text('Coach Setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label('Full Name'),
                TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: _dec('Enter your full name'), validator: _required),
                const SizedBox(height: 16),
                _label('Primary Sport'),
                _DropdownField(
                  value: _sportId,
                  hint: 'Select sport',
                  items: meta.sports.map((s) => _DropdownItem(value: s.id, label: s.name)).toList(),
                  onChanged: (v) => setState(() => _sportId = v),
                ),
                const SizedBox(height: 16),
                _label('City'),
                _DropdownField(
                  value: _cityId,
                  hint: 'Select city',
                  items: meta.cities.map((c) => _DropdownItem(value: c.id, label: '${c.name}, ${c.state}')).toList(),
                  onChanged: (v) => setState(() => _cityId = v),
                ),
                const SizedBox(height: 16),
                _label('Contact Number'),
                TextFormField(controller: _contact, keyboardType: TextInputType.phone, decoration: _dec('e.g. +91 98765 43210'), validator: _required),
                const SizedBox(height: 16),
                _label('Experience (years)'),
                TextFormField(controller: _experience, keyboardType: TextInputType.number, decoration: _dec('e.g. 9'), validator: _required),
                const SizedBox(height: 16),
                _label('Qualification (optional)'),
                TextFormField(controller: _qualification, decoration: _dec('e.g. BCCI Level-A certified')),
                const SizedBox(height: 16),
                _label('Fee Structure (optional)'),
                TextFormField(controller: _fee, decoration: _dec('e.g. ₹800/session')),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _saving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
      );

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
}

class _DropdownItem {
  final int value;
  final String label;
  const _DropdownItem({required this.value, required this.label});
}

class _DropdownField extends StatelessWidget {
  final int? value;
  final String hint;
  final List<_DropdownItem> items;
  final ValueChanged<int?> onChanged;
  const _DropdownField({required this.value, required this.hint, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: const InputDecoration(border: InputBorder.none),
        hint: Text(hint, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        isExpanded: true,
        items: items
            .map((i) => DropdownMenuItem<int>(value: i.value, child: Text(i.label, style: const TextStyle(fontSize: 15))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
