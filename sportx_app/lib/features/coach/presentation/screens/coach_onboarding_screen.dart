import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class CoachOnboardingScreen extends ConsumerStatefulWidget {
  const CoachOnboardingScreen({super.key});

  @override
  ConsumerState<CoachOnboardingScreen> createState() => _CoachOnboardingScreenState();
}

class _CoachOnboardingScreenState extends ConsumerState<CoachOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  String? _experience;
  final _qualificationController = TextEditingController();
  final _feeController = TextEditingController();
  final _bioController = TextEditingController();

  int? _sportId;
  int? _cityId;
  bool _personalCoaching = false;
  final List<String> _experienceOptions = ['1-3 years', '3-5 years', '5-10 years', '10+ years'];
  final List<String> _certifications = [];
  final List<String> _languages = [];
  final _certificationController = TextEditingController();
  final _languageController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _qualificationController.dispose();
    _feeController.dispose();
    _bioController.dispose();
    _certificationController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  void _addCertification() {
    final text = _certificationController.text.trim();
    if (text.isNotEmpty && !_certifications.contains(text)) {
      setState(() {
        _certifications.add(text);
        _certificationController.clear();
      });
    }
  }

  void _removeCertification(String cert) {
    setState(() => _certifications.remove(cert));
  }

  void _addLanguage() {
    final text = _languageController.text.trim();
    if (text.isNotEmpty && !_languages.contains(text)) {
      setState(() {
        _languages.add(text);
        _languageController.clear();
      });
    }
  }

  void _removeLanguage(String lang) {
    setState(() => _languages.remove(lang));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_sportId == null || _cityId == null) {
      SnackBarUtils.showSuccess(context, 'Please select sport and city');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).post('/onboarding/coach', data: {
        'full_name': _nameController.text.trim(),
        'sport_id': _sportId,
        'city_id': _cityId,
        'contact_number': _contactController.text.trim(),
        'experience': _experience ?? '',
        if (_qualificationController.text.trim().isNotEmpty)
          'qualification': _qualificationController.text.trim(),
        if (_feeController.text.trim().isNotEmpty)
          'fee_structure': _feeController.text.trim(),
        if (_bioController.text.trim().isNotEmpty)
          'bio': _bioController.text.trim(),
        'personal_coaching': _personalCoaching,
        if (_certifications.isNotEmpty) 'certifications': _certifications,
        if (_languages.isNotEmpty) 'languages': _languages,
      });
      ref.read(authProvider.notifier).markOnboardingComplete();
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) context.go('/coach-dashboard');
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e is DioException ? ApiException.fromDio(e as DioException) : e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 24),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coach Setup',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            Text(
              'Tell us about your coaching',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProgressBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('Full Name'),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration('Enter your full name'),
                        validator: _required,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Primary Sport'),
                      _buildSportChips(meta.sports),
                      const SizedBox(height: 20),
                      _buildSectionLabel('City'),
                      _DropdownField(
                        value: _cityId,
                        hint: 'Select city',
                        items: meta.cities
                            .map((c) => _DropdownItem(value: c.id, label: '${c.name}, ${c.state}'))
                            .toList(),
                        onChanged: (v) => setState(() => _cityId = v),
                        validator: _requiredDropdown,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Contact Number'),
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('e.g. +91 98765 43210'),
                        validator: _required,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Experience (years)'),
                      _DropdownField(
                        value: _experience == null ? null : _experienceOptions.indexOf(_experience!),
                        hint: 'Select experience',
                        items: _experienceOptions
                            .asMap()
                            .entries
                            .map((e) => _DropdownItem(value: e.key, label: e.value))
                            .toList(),
                        onChanged: (v) => setState(() => _experience = v == null ? null : _experienceOptions[v]),
                        validator: (v) => v == null ? 'Please select an option' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Qualification (optional)'),
                      TextFormField(
                        controller: _qualificationController,
                        decoration: _inputDecoration('e.g. BCCI Level-A certified'),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Certifications (optional)'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _certificationController,
                              decoration: _inputDecoration('e.g. AIFF C License'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addCertification,
                            icon: const Icon(LucideIcons.plus, color: AppColors.primary),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                      if (_certifications.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _certifications.map((cert) {
                            return Chip(
                              label: Text(cert, style: const TextStyle(fontSize: 12)),
                              deleteIcon: const Icon(LucideIcons.x, size: 14),
                              onDeleted: () => _removeCertification(cert),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _buildSectionLabel('Languages Spoken (optional)'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _languageController,
                              decoration: _inputDecoration('e.g. English, Hindi'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addLanguage,
                            icon: const Icon(LucideIcons.plus, color: AppColors.primary),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                      if (_languages.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _languages.map((lang) {
                            return Chip(
                              label: Text(lang, style: const TextStyle(fontSize: 12)),
                              deleteIcon: const Icon(LucideIcons.x, size: 14),
                              onDeleted: () => _removeLanguage(lang),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _buildSectionLabel('Fee Structure (optional)'),
                      TextFormField(
                        controller: _feeController,
                        decoration: _inputDecoration('e.g. ₹800/session or ₹5000/month'),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Bio (optional)'),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: _inputDecoration('Describe your coaching approach and achievements...'),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Personal Coaching',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'I offer one-on-one coaching sessions',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _personalCoaching,
                              onChanged: (v) => setState(() => _personalCoaching = v),
                              activeThumbColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.ink,
                      disabledBackgroundColor: AppColors.border,
                      disabledForegroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Complete Setup',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
      );

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _requiredDropdown(int? v) =>
      v == null ? 'Please select an option' : null;

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSportIcon(String name) {
    switch (name.toLowerCase()) {
      case 'football': return LucideIcons.goal;
      case 'basketball': return LucideIcons.circle;
      case 'cricket': return LucideIcons.circleDot;
      case 'athletics': return LucideIcons.footprints;
      case 'swimming': return LucideIcons.waves;
      case 'tennis': return LucideIcons.circleDot;
      case 'badminton': return LucideIcons.circleDot;
      case 'table tennis': return LucideIcons.table2;
      case 'chess': return LucideIcons.brain;
      case 'martial arts': return LucideIcons.swords;
      default: return LucideIcons.activity;
    }
  }

  Widget _buildSportChips(List<dynamic> sports) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sports.map((s) {
        final isSelected = _sportId == s.id;
        return GestureDetector(
          onTap: () => setState(() => _sportId = s.id as int?),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.yellow : AppColors.background,
              border: Border.all(color: isSelected ? AppColors.yellowDeep : AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getSportIcon(s.name as String),
                  size: 16,
                  color: isSelected ? AppColors.ink : AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  s.name as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.ink : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
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
  final String? Function(int?)? validator;

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<int>(
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: state.hasError ? Colors.red : AppColors.border,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: value,
                  hint: Text(hint, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  isExpanded: true,
                  icon: const Icon(LucideIcons.chevronDown, size: 20, color: AppColors.textSecondary),
                  items: items
                      .map((i) => DropdownMenuItem<int>(
                            value: i.value,
                            child: Text(i.label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    onChanged(v);
                    state.didChange(v);
                  },
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }
}
