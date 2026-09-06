import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/talent_scout/data/models/talent_scout_profile.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/talent_scout_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class TalentScoutOnboardingScreen extends ConsumerStatefulWidget {
  const TalentScoutOnboardingScreen({super.key});

  @override
  ConsumerState<TalentScoutOnboardingScreen> createState() => _TalentScoutOnboardingScreenState();
}

class _TalentScoutOnboardingScreenState extends ConsumerState<TalentScoutOnboardingScreen> {
  final _organization = TextEditingController();
  final _affiliation = TextEditingController();
  final _bio = TextEditingController();
  int? _experienceYears;
  final Set<int> _selectedSports = {};
  bool _saving = false;

  @override
  void dispose() {
    _organization.dispose();
    _affiliation.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedSports.isEmpty) {
      SnackBarUtils.showError(context, 'Please select at least one sport');
      return;
    }
    setState(() => _saving = true);
    try {
      final profile = TalentScoutProfile(
        userId: 0,
        organization: _organization.text.trim().isNotEmpty ? _organization.text.trim() : null,
        affiliation: _affiliation.text.trim().isNotEmpty ? _affiliation.text.trim() : null,
        sportsSpecialization: _selectedSports.toList(),
        experienceYears: _experienceYears,
        bio: _bio.text.trim().isNotEmpty ? _bio.text.trim() : null,
      );
      final success = await ref.read(talentScoutProvider.notifier).createProfile(profile);
      if (mounted) {
        if (success) {
          ref.read(authProvider.notifier).markOnboardingComplete();
          await ref.read(authProvider.notifier).refreshUser();
          if (!mounted) return;
          SnackBarUtils.showSuccess(context, 'Profile created successfully');
          context.go('/scout-dashboard');
        } else {
          SnackBarUtils.showError(context, 'Failed to create profile');
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Set up your scout profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _organization,
              decoration: const InputDecoration(labelText: 'Organization (optional)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _affiliation,
              decoration: const InputDecoration(labelText: 'Affiliation (optional)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _experienceYears,
              decoration: const InputDecoration(labelText: 'Years of Experience'),
              items: List.generate(31, (i) => DropdownMenuItem(value: i, child: Text('$i years'))),
              onChanged: (v) => setState(() => _experienceYears = v),
            ),
            const SizedBox(height: 16),
            const Text('Sports Specialization *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSportChip(1, 'Cricket'),
                _buildSportChip(2, 'Football'),
                _buildSportChip(3, 'Kabaddi'),
                _buildSportChip(4, 'Badminton'),
                _buildSportChip(5, 'Tennis'),
                _buildSportChip(6, 'Athletics'),
                _buildSportChip(7, 'Hockey'),
                _buildSportChip(8, 'Chess'),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bio,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio (optional)', alignLabelWithHint: true),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportChip(int id, String label) {
    final selected = _selectedSports.contains(id);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        setState(() {
          if (val) {
            _selectedSports.add(id);
          } else {
            _selectedSports.remove(id);
          }
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
