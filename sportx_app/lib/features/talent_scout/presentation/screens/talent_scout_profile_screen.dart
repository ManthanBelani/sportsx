import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/talent_scout_provider.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class TalentScoutProfileScreen extends ConsumerStatefulWidget {
  const TalentScoutProfileScreen({super.key});

  @override
  ConsumerState<TalentScoutProfileScreen> createState() => _TalentScoutProfileScreenState();
}

class _TalentScoutProfileScreenState extends ConsumerState<TalentScoutProfileScreen> {
  final _org = TextEditingController();
  final _affiliation = TextEditingController();
  final _bio = TextEditingController();
  int? _exp;
  int? _cityId;
  Set<int> _sports = {};
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(talentScoutProvider.notifier).loadProfile();
      final p = ref.read(talentScoutProvider).profile;
      if (p != null && mounted) {
        setState(() {
          _org.text = p.organization ?? '';
          _affiliation.text = p.affiliation ?? '';
          _bio.text = p.bio ?? '';
          _exp = p.experienceYears;
          _cityId = p.cityId;
          _sports = p.sportsSpecialization.toSet();
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  void dispose() {
    _org.dispose();
    _affiliation.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_sports.isEmpty) {
      SnackBarUtils.showError(context, 'Select at least one sport');
      return;
    }
    setState(() => _saving = true);
    try {
      final ok = await ref.read(talentScoutProvider.notifier).updateProfile({
        'organization': _org.text.trim().isEmpty ? null : _org.text.trim(),
        'affiliation': _affiliation.text.trim().isEmpty ? null : _affiliation.text.trim(),
        'sports_specialization': _sports.toList(),
        'experience_years': _exp,
        'city_id': _cityId,
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
      });
      if (mounted) {
        if (ok) {
          SnackBarUtils.showSuccess(context, 'Profile updated');
          context.pop();
        } else {
          SnackBarUtils.showError(context, ref.read(talentScoutProvider).error ?? 'Failed to update');
        }
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Scout Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: _org, decoration: const InputDecoration(labelText: 'Organization', hintText: 'Elite Talent Agency')),
          const SizedBox(height: 16),
          TextField(controller: _affiliation, decoration: const InputDecoration(labelText: 'Affiliation', hintText: 'Gujarat Cricket Association')),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _exp,
            decoration: const InputDecoration(labelText: 'Years of Experience'),
            items: List.generate(31, (i) => DropdownMenuItem(value: i, child: Text('$i years'))),
            onChanged: (v) => setState(() => _exp = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _cityId,
            decoration: const InputDecoration(labelText: 'City'),
            hint: const Text('Select city'),
            items: meta.cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() => _cityId = v),
          ),
          const SizedBox(height: 16),
          const Text('Sports Specialization *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: meta.sports.map((s) {
              final sel = _sports.contains(s.id);
              return FilterChip(
                label: Text(s.name),
                selected: sel,
                onSelected: (v) => setState(() {
                  if (v) _sports.add(s.id);
                  else _sports.remove(s.id);
                }),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(color: sel ? AppColors.primary : AppColors.textSecondary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(controller: _bio, maxLines: 4, decoration: const InputDecoration(labelText: 'Bio', hintText: 'Describe your scouting background...', alignLabelWithHint: true)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}
