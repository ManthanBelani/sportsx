import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class CoachProfilePostingScreen extends ConsumerStatefulWidget {
  const CoachProfilePostingScreen({super.key});

  @override
  ConsumerState<CoachProfilePostingScreen> createState() => _CoachProfilePostingScreenState();
}

class _CoachProfilePostingScreenState extends ConsumerState<CoachProfilePostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _headline = TextEditingController();
  final _location = TextEditingController();
  final _bio = TextEditingController();
  final _feeSession = TextEditingController();
  final _feeMonthly = TextEditingController();
  final _feeQuarterly = TextEditingController();

  int? _cityId;
  int? _sportId;
  String? _experience;
  final _experienceOptions = ['1-3 years', '3-5 years', '5-10 years', '10+ years'];
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _headline.dispose();
    _location.dispose();
    _bio.dispose();
    _feeSession.dispose();
    _feeMonthly.dispose();
    _feeQuarterly.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_sportId == null || _cityId == null || _experience == null) {
      SnackBarUtils.showError(context, 'Please select sport, city and experience');
      return;
    }
    setState(() => _saving = true);
    try {
      final fee = 'Session: ₹${_feeSession.text.trim()} | Monthly: ₹${_feeMonthly.text.trim()} | Quarterly: ₹${_feeQuarterly.text.trim()}';
      await ref.read(dioProvider).put('/me/coach-profile', data: {
        'full_name': '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim(),
        'sport_id': _sportId,
        'city_id': _cityId,
        'contact_number': 'N/A',
        'experience': _experience,
        'headline': _headline.text.trim(),
        'fee_structure': fee,
        'bio': _bio.text.trim(),
        'location': _location.text.trim(),
      });
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Profile Updated!');
        context.pop();
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e is DioException ? ApiException.fromDio(e as DioException) : e);
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
        title: const Text('Edit My Listing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: TextFormField(controller: _firstName, decoration: const InputDecoration(labelText: 'First Name', hintText: 'Rahul'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _lastName, decoration: const InputDecoration(labelText: 'Last Name', hintText: 'Sharma'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
            ]),
            const SizedBox(height: 16),
            TextFormField(controller: _headline, decoration: const InputDecoration(labelText: 'Headline', hintText: 'AIFF Certified Football Coach')),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _sportId,
              decoration: const InputDecoration(labelText: 'Primary Sport'),
              hint: const Text('Select sport'),
              items: meta.sports.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (v) => setState(() => _sportId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _cityId,
              decoration: const InputDecoration(labelText: 'City'),
              hint: const Text('Select city'),
              items: meta.cities.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name}, ${c.state}'))).toList(),
              onChanged: (v) => setState(() => _cityId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'Area / Location', hintText: 'Indiranagar, Bangalore')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _experience,
              decoration: const InputDecoration(labelText: 'Experience'),
              hint: const Text('Select experience'),
              items: _experienceOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _experience = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            const Text('Fee Structure', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TextField(controller: _feeSession, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Per Session', prefixText: '₹ ', hintText: '800')),
            const SizedBox(height: 8),
            TextField(controller: _feeMonthly, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly', prefixText: '₹ ', hintText: '5000')),
            const SizedBox(height: 8),
            TextField(controller: _feeQuarterly, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quarterly', prefixText: '₹ ', hintText: '13000')),
            const SizedBox(height: 16),
            TextFormField(controller: _bio, decoration: const InputDecoration(labelText: 'Bio', hintText: 'Describe your coaching philosophy...'), maxLines: 4),
            const SizedBox(height: 20),
            const Text('Weekly Availability', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: const Text('Set your weekly slots in the full editor (Mon–Sun, 4–6 PM etc.)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
