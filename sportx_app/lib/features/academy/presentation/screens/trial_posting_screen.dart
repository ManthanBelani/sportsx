import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';

const _documentOptions = [
  'Age Proof',
  'Previous Team/Club Certificate',
  'Medical Fitness Certificate',
  'Parent Consent Form',
];

class TrialPostingScreen extends ConsumerStatefulWidget {
  const TrialPostingScreen({super.key});

  @override
  ConsumerState<TrialPostingScreen> createState() => _TrialPostingScreenState();
}

class _TrialPostingScreenState extends ConsumerState<TrialPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _venue = TextEditingController();
  final _eligibility = TextEditingController();
  final _fee = TextEditingController();
  final _maxRegistrations = TextEditingController();
  final _contact = TextEditingController();
  int? _sportId;
  int? _cityId;
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  DateTime? _deadline;
  final Set<String> _docs = {};
  final Set<String> _selectedAgeChips = {};
  final List<String> _ageChipOptions = ['U-10', 'U-14', 'U-16', 'U-18', 'Open'];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    _eligibility.dispose();
    _fee.dispose();
    _maxRegistrations.dispose();
    _contact.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _dateLabel =>
      _eventDate == null ? '' : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}';

  String get _timeLabel => _eventTime == null
      ? ''
      : '${_two(_eventTime!.hour)}:${_two(_eventTime!.minute)}';

  Future<void> _save({required bool publish}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_eventDate == null || _eventTime == null) {
      SnackBarUtils.showError(context, 'Please select the trial date and time');
      return;
    }
    final eventDateTime = DateTime(
      _eventDate!.year, _eventDate!.month, _eventDate!.day,
      _eventTime!.hour, _eventTime!.minute,
    );
    if (!eventDateTime.isAfter(DateTime.now())) {
      SnackBarUtils.showError(context, 'Trial date & time must be in the future');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(providerTrialActionsProvider).create({
        'name': _name.text.trim(),
        'sport_id': _sportId,
        'city_id': _cityId,
        'venue': _venue.text.trim(),
        'event_datetime':
            '${eventDateTime.year}-${_two(eventDateTime.month)}-${_two(eventDateTime.day)} ${_two(eventDateTime.hour)}:${_two(eventDateTime.minute)}:00',
        if (_deadline != null)
          'registration_deadline': '${_deadline!.year}-${_two(_deadline!.month)}-${_two(_deadline!.day)}',
        if (_selectedAgeChips.isNotEmpty || _eligibility.text.trim().isNotEmpty)
          'eligibility': [
            if (_selectedAgeChips.isNotEmpty) _selectedAgeChips.join(', '),
            if (_eligibility.text.trim().isNotEmpty) _eligibility.text.trim(),
          ].join(' • '),
        if (_maxRegistrations.text.trim().isNotEmpty)
          'vacancies': int.tryParse(_maxRegistrations.text.trim()),
        if (_fee.text.trim().isNotEmpty) 'entry_fee': _fee.text.trim(),
        'required_documents': _docs.toList(),
        'contact_number': _contact.text.trim(),
        'status': publish ? 'published' : 'draft',
      });
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, publish ? 'Trial Published!' : 'Draft saved');
      context.pop();
    } on DioException catch (e) {
      if (mounted) SnackBarUtils.showError(context, ApiException.fromDio(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate({required bool isDeadline}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isDeadline ? (_deadline ?? now) : (_eventDate ?? now),
      firstDate: isDeadline ? now : now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => isDeadline ? _deadline = picked : _eventDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _eventTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _eventTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Trial Title'),
              TextFormField(
                controller: _name,
                decoration: _dec('e.g. Open Football Trials - December'),
                validator: _req,
              ),
              const SizedBox(height: 16),
              _label('Sport'),
              _dropdown(
                value: _sportId,
                hint: 'Select sport',
                items: meta.sports.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (v) => setState(() => _sportId = v),
                validator: (v) => v == null ? 'Select a sport' : null,
              ),
              const SizedBox(height: 16),
              _label('Eligibility — Age Groups'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ageChipOptions.map((age) {
                  final selected = _selectedAgeChips.contains(age);
                  return FilterChip(
                    label: Text(age),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedAgeChips.add(age);
                      } else {
                        _selectedAgeChips.remove(age);
                      }
                    }),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _eligibility,
                decoration: _dec('Additional eligibility (e.g. Boys, Ahmedabad residents)'),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Date'),
                        TextFormField(
                          readOnly: true,
                          controller: TextEditingController(text: _dateLabel),
                          decoration: _dec('Select date', icon: LucideIcons.calendar),
                          onTap: () => _pickDate(isDeadline: false),
                          validator: (_) => _eventDate == null ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Time'),
                        TextFormField(
                          readOnly: true,
                          controller: TextEditingController(text: _timeLabel),
                          decoration: _dec('Select time', icon: LucideIcons.clock),
                          onTap: _pickTime,
                          validator: (_) => _eventTime == null ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label('Registration Deadline (optional)'),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                    text: _deadline == null
                        ? ''
                        : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'),
                decoration: _dec('Select deadline date', icon: LucideIcons.calendar),
                onTap: () => _pickDate(isDeadline: true),
              ),
              const SizedBox(height: 16),
              _label('City'),
              _dropdown(
                value: _cityId,
                hint: 'Select city',
                items: meta.cities
                    .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name}, ${c.state}')))
                    .toList(),
                onChanged: (v) => setState(() => _cityId = v),
                validator: (v) => v == null ? 'Select a city' : null,
              ),
              const SizedBox(height: 16),
              _label('Venue'),
              TextFormField(
                controller: _venue,
                decoration: _dec('e.g. Academy Ground, Indiranagar'),
                validator: _req,
              ),
              const SizedBox(height: 16),
              _label('Entry Fee (optional)'),
              TextFormField(
                controller: _fee,
                decoration: _dec('e.g. ₹200'),
              ),
              const SizedBox(height: 16),
              _label('Maximum Registrations'),
              TextFormField(
                controller: _maxRegistrations,
                keyboardType: TextInputType.number,
                decoration: _dec('e.g. 50'),
              ),
              const SizedBox(height: 16),
              _label('Required Documents'),
              ..._documentOptions.map(_buildDocCheckbox),
              const SizedBox(height: 16),
              _label('Contact Number'),
              TextFormField(
                controller: _contact,
                keyboardType: TextInputType.phone,
                decoration: _dec('e.g. +91 98765 43210'),
                validator: _req,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => _save(publish: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Save as Draft',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : () => _save(publish: true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Publish Trial',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocCheckbox(String label) {
    final selected = _docs.contains(label);
    return InkWell(
      onTap: () => setState(() => selected ? _docs.remove(label) : _docs.add(label)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (_) => setState(() => selected ? _docs.remove(label) : _docs.add(label)),
              activeColor: AppColors.primary,
            ),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      );

  InputDecoration _dec(String hint, {IconData? icon}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.textSecondary) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
      );

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _dropdown({
    required dynamic value,
    required String hint,
    required List<DropdownMenuItem<dynamic>> items,
    required ValueChanged<dynamic> onChanged,
    String? Function(dynamic)? validator,
  }) {
    return DropdownButtonFormField<dynamic>(
      initialValue: value,
      decoration: _dec(hint),
      isExpanded: true,
      icon: const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textSecondary),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
