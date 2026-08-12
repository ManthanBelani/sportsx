import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class AcademyOnboardingScreen extends ConsumerStatefulWidget {
  const AcademyOnboardingScreen({super.key});

  @override
  ConsumerState<AcademyOnboardingScreen> createState() => _AcademyOnboardingScreenState();
}

class _AcademyOnboardingScreenState extends ConsumerState<AcademyOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _fee = TextEditingController();
  int? _cityId;
  final Set<int> _sportIds = {};
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _contact.dispose();
    _fee.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_cityId == null || _sportIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select city and at least one sport')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).post('/onboarding/academy', data: {
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'address': _address.text.trim(),
        'city_id': _cityId,
        'contact_number': _contact.text.trim(),
        'sports': _sportIds.toList(),
        if (_fee.text.trim().isNotEmpty) 'fee_range': _fee.text.trim(),
      });
      ref.read(authProvider.notifier).markOnboardingComplete();
      if (mounted) context.go('/academy-dashboard');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
        title: const Text('Academy Setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label('Academy Name'),
                TextFormField(controller: _name, decoration: _dec('e.g. Elite Cricket Academy'), validator: _req),
                const SizedBox(height: 16),
                _label('Description'),
                TextFormField(controller: _description, maxLines: 3, decoration: _dec('Short description of your academy'), validator: _req),
                const SizedBox(height: 16),
                _label('Address'),
                TextFormField(controller: _address, decoration: _dec('Full address'), validator: _req),
                const SizedBox(height: 16),
                _label('City'),
                _dropdown(
                  value: _cityId,
                  hint: 'Select city',
                  items: meta.cities.map((c) => _Item(c.id, '${c.name}, ${c.state}')).toList(),
                  onChanged: (v) => setState(() => _cityId = v),
                ),
                const SizedBox(height: 16),
                _label('Contact Number'),
                TextFormField(controller: _contact, keyboardType: TextInputType.phone, decoration: _dec('e.g. +91 98765 43210'), validator: _req),
                const SizedBox(height: 16),
                _label('Sports Offered'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: meta.sports.map((s) {
                    final selected = _sportIds.contains(s.id);
                    return ChoiceChip(
                      label: Text(s.name),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w500),
                      onSelected: (sel) => setState(() => sel ? _sportIds.add(s.id) : _sportIds.remove(s.id)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _label('Fee Range (optional)'),
                TextFormField(controller: _fee, decoration: _dec('e.g. ₹2,000 – ₹5,000/mo')),
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

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _dropdown({
    required int? value,
    required String hint,
    required List<_Item> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: const InputDecoration(border: InputBorder.none),
        hint: Text(hint, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        isExpanded: true,
        items: items.map((i) => DropdownMenuItem<int>(value: i.value, child: Text(i.label))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _Item {
  final int value;
  final String label;
  const _Item(this.value, this.label);
}
