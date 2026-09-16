import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/sponsor/presentation/providers/sponsor_provider.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class SponsorshipPostingScreen extends ConsumerStatefulWidget {
  const SponsorshipPostingScreen({super.key});

  @override
  ConsumerState<SponsorshipPostingScreen> createState() => _SponsorshipPostingScreenState();
}

class _SponsorshipPostingScreenState extends ConsumerState<SponsorshipPostingScreen> {
  final _title = TextEditingController();
  final _grantAmount = TextEditingController();
  final _eligibility = TextEditingController();
  final _deadline = TextEditingController();
  final List<TextEditingController> _benefits = [TextEditingController(text: '₹50,000 grant')];
  final Set<int> _selectedSportIds = {};
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _grantAmount.dispose();
    _eligibility.dispose();
    _deadline.dispose();
    for (final c in _benefits) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (d != null) {
      _deadline.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Title is required');
      return;
    }
    if (_selectedSportIds.isEmpty) {
      SnackBarUtils.showError(context, 'Select at least one sport');
      return;
    }
    setState(() => _saving = true);
    final benefitsList = _benefits.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    final ok = await ref.read(sponsorshipActionsProvider).create({
      'title': _title.text.trim(),
      'sport_ids': _selectedSportIds.toList(),
      // keep legacy single sport field for backend compat
      'sport': _selectedSportIds.first.toString(),
      'grant_amount': _grantAmount.text.trim(),
      'eligibility': _eligibility.text.trim(),
      'benefits': benefitsList.join(' | '),
      'benefits_list': benefitsList,
      'application_deadline': _deadline.text.trim(),
      'deadline': _deadline.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      SnackBarUtils.showSuccess(context, 'Sponsorship saved!');
      context.pop();
    } else {
      SnackBarUtils.showError(context, 'Failed to save');
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
        title: const Text('Create Sponsorship',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Opportunity Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Opportunity Title', hintText: 'e.g. Rising Stars Cricket Scholarship')),
            const SizedBox(height: 16),
            const Text('Sports', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            if (meta.sports.isEmpty)
              const Text('Loading sports...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: meta.sports.map((s) {
                  final selected = _selectedSportIds.contains(s.id);
                  return FilterChip(
                    label: Text(s.name),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedSportIds.add(s.id);
                      } else {
                        _selectedSportIds.remove(s.id);
                      }
                    }),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _grantAmount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Grant Amount', hintText: '₹50,000', prefixText: '₹ '),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickDeadline,
              child: AbsorbPointer(
                child: TextField(
                  controller: _deadline,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Deadline',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: Icon(LucideIcons.calendar, size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _eligibility,
              decoration: const InputDecoration(labelText: 'Eligibility Criteria', hintText: 'Age 12-20, state-level players...'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Text('Benefits Offered', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ..._benefits.asMap().entries.map((entry) {
              final idx = entry.key;
              final ctrl = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: ctrl, decoration: InputDecoration(hintText: idx == 0 ? '₹50,000 grant' : 'Benefit ${idx + 1}'))),
                    const SizedBox(width: 8),
                    if (_benefits.length > 1)
                      IconButton(
                        onPressed: () => setState(() {
                          ctrl.dispose();
                          _benefits.removeAt(idx);
                        }),
                        icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
                        style: IconButton.styleFrom(backgroundColor: AppColors.surface, side: const BorderSide(color: AppColors.border)),
                      )
                    else
                      const SizedBox(width: 40),
                  ],
                ),
              );
            }),
            InkWell(
              onTap: () => setState(() => _benefits.add(TextEditingController())),
              child: Row(children: const [
                Icon(LucideIcons.plus, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text('+ Add Benefit', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save & Publish', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
