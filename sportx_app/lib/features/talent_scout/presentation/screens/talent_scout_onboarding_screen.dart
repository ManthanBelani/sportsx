import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/talent_scout/data/models/talent_scout_profile.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/talent_scout_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/media_picker.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
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
  int? _cityId;
  final Set<int> _selectedSports = {};
  bool _saving = false;
  int? _photoMediaId;
  String? _photoUrl;

  @override
  void dispose() {
    _organization.dispose();
    _affiliation.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final media = await pickAndUploadMedia(context, ref, mediaType: 'photo');
    if (media != null && mounted) {
      setState(() {
        _photoMediaId = media.mediaId;
        _photoUrl = media.url;
      });
      SnackBarUtils.showSuccess(context, 'Photo uploaded');
    }
  }

  Future<void> _submit() async {
    if (_selectedSports.isEmpty) {
      SnackBarUtils.showError(context, 'Please select at least one sport specialization');
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
        cityId: _cityId,
        bio: _bio.text.trim().isNotEmpty ? _bio.text.trim() : null,
        photoMediaId: _photoMediaId,
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
          SnackBarUtils.showError(context, ref.read(talentScoutProvider).error ?? 'Failed to create profile');
        }
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e, 'Failed to save profile. Please try again.');
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text('Set up your scout profile',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.pop()),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Header
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                child: const Text('Step 1 of 1 — Scout Profile Setup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
              const SizedBox(height: 12),
              const Text('Professional details help athletes trust your outreach', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ]),
          ),
          Container(height: 8, color: AppColors.surface),
          // Photo
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(children: [
              Semantics(
                label: 'Profile photo',
                button: true,
                child: InkWell(
                  onTap: _pickPhoto,
                  borderRadius: BorderRadius.circular(48),
                  child: Stack(alignment: Alignment.bottomRight, children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.primary, AppColors.scout], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                      child: ClipOval(
                        child: _photoUrl != null
                            ? Image.network(MediaUtils.resolveUrl(_photoUrl), width: 96, height: 96, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(LucideIcons.user, size: 48, color: Colors.white))
                            : const Icon(LucideIcons.user, size: 48, color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.camera, size: 14, color: Colors.white),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              Text(_photoUrl == null ? 'Tap to add profile photo (optional)' : 'Photo ready — tap to change', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          Container(height: 8, color: AppColors.surface),
          // Form
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(controller: _organization, decoration: const InputDecoration(labelText: 'Organization', hintText: 'Elite Talent Agency (optional)')),
              const SizedBox(height: 16),
              TextField(controller: _affiliation, decoration: const InputDecoration(labelText: 'Affiliation', hintText: 'Gujarat Cricket Association (optional)')),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(initialValue: _experienceYears,
                decoration: const InputDecoration(labelText: 'Years of Experience'),
                items: List.generate(31, (i) => DropdownMenuItem(value: i, child: Text('$i years'))),
                onChanged: (v) => setState(() => _experienceYears = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(initialValue: _cityId,
                decoration: const InputDecoration(labelText: 'City'),
                hint: const Text('Select city'),
                items: meta.cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _cityId = v),
              ),
              const SizedBox(height: 16),
              const Text('Sports Specialization *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              if (meta.sports.isEmpty)
                const Text('Loading sports...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: meta.sports.map((s) => _buildSportChip(s.id, s.name)).toList(),
                ),
              const SizedBox(height: 16),
              TextField(controller: _bio, maxLines: 4, decoration: const InputDecoration(labelText: 'Bio (optional)', hintText: 'Tell athletes about your scouting background...', alignLabelWithHint: true)),
              const SizedBox(height: 8),
              const Text('Visible on your public scout card', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create Scout Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildSportChip(int id, String label) {
    final selected = _selectedSports.contains(id);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) => setState(() => val ? _selectedSports.add(id) : _selectedSports.remove(id)),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
    );
  }
}
