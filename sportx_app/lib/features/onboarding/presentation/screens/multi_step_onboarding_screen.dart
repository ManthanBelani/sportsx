import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/role_config.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/onboarding/presentation/providers/multi_step_onboarding_provider.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';

/// Progressive multi-step onboarding screen for all roles
class MultiStepOnboardingScreen extends ConsumerStatefulWidget {
  const MultiStepOnboardingScreen({super.key});

  @override
  ConsumerState<MultiStepOnboardingScreen> createState() => _MultiStepOnboardingScreenState();
}

class _MultiStepOnboardingScreenState extends ConsumerState<MultiStepOnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final role = authState.user?.role != null
        ? sportXRoleFromId(authState.user!.role)
        : SportXRole.athlete;
    
    final onboarding = ref.watch(multiStepOnboardingProvider(role ?? SportXRole.athlete));
    final steps = _getStepsForRole(role ?? SportXRole.athlete);

    if (steps.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final targetPage = steps.indexOf(onboarding.currentStep);
    if (targetPage != _currentPage && _pageController.hasClients) {
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _currentPage = targetPage;
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SportXTopBar(
        title: 'Welcome to SportX',
        showBack: onboarding.currentStep != OnboardingStep.coreIdentity,
        onBack: () => _handleBack(ref, onboarding, steps, role ?? SportXRole.athlete),
      ),
      body: Column(
        children: [
          _buildProgressBar(onboarding, steps),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: steps.map((step) => _buildStepContent(context, ref, step, onboarding, role ?? SportXRole.athlete)).toList(),
            ),
          ),
          _buildNavigationButtons(context, ref, onboarding, steps, role ?? SportXRole.athlete),
        ],
      ),
    );
  }

  Widget _buildProgressBar(OnboardingProgress progress, List<OnboardingStep> steps) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isActive = step == progress.currentStep;
              final isComplete = progress.isStepComplete(step);
              
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive || isComplete ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < steps.length - 1) const SizedBox(width: 8),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                onboardingStepInfo[progress.currentStep]?.icon ?? LucideIcons.helpCircle,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      onboardingStepInfo[progress.currentStep]?.title ?? 'Step ${steps.indexOf(progress.currentStep) + 1}',
                      style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    Text(
                      onboardingStepInfo[progress.currentStep]?.subtitle ?? '',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '${steps.indexOf(progress.currentStep) + 1} / ${steps.length}',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, WidgetRef ref, OnboardingStep step, OnboardingProgress progress, SportXRole role) {
    final notifier = ref.read(multiStepOnboardingProvider(role).notifier);
    
    switch (step) {
      case OnboardingStep.coreIdentity:
        return _CoreIdentityStep(notifier: notifier);
      case OnboardingStep.roleProfile:
        return _RoleProfileStep(notifier: notifier, role: role);
      case OnboardingStep.media:
        return _MediaStep(notifier: notifier);
      case OnboardingStep.verification:
        return _VerificationStep(notifier: notifier);
      case OnboardingStep.preferences:
        return _PreferencesStep(notifier: notifier);
      case OnboardingStep.complete:
        return const _CompletionStep();
    }
  }

  Widget _buildNavigationButtons(BuildContext context, WidgetRef ref, OnboardingProgress progress, List<OnboardingStep> steps, SportXRole role) {
    final isLastStep = progress.currentStep == steps.last;
    final isFirstStep = progress.currentStep == steps.first;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Row(
        children: [
          if (!isFirstStep)
            Expanded(
              child: OutlinedButton(
                onPressed: () => ref.read(multiStepOnboardingProvider(role).notifier).previousStep(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.arrowLeft, size: 18),
                    const SizedBox(width: 8),
                    Text('Back', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
          if (!isFirstStep) const SizedBox(width: 12),
          Expanded(
            flex: isFirstStep ? 1 : 1,
            child: PrimaryButton(
              label: isLastStep ? 'Complete' : 'Continue',
              icon: isLastStep ? LucideIcons.check : LucideIcons.arrowRight,
              onPressed: () async {
                final notifier = ref.read(multiStepOnboardingProvider(role).notifier);
                final missing = notifier.validateCurrentStep();
                if (missing.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill in: ${missing.join(', ')}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                if (isLastStep) {
                  await _submitOnboarding(ref, role);
                } else {
                  notifier.completeStep();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitOnboarding(WidgetRef ref, SportXRole role) async {
    final notifier = ref.read(multiStepOnboardingProvider(role).notifier);
    try {
      await notifier.submit();
      if (mounted) {
        ref.read(authProvider.notifier).markOnboardingComplete();
        context.go('/home');
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.fromDio(e).message)),
        );
      }
    }
  }

  void _handleBack(WidgetRef ref, OnboardingProgress progress, List<OnboardingStep> steps, SportXRole role) {
    if (progress.currentStep == steps.first) {
      context.go('/home');
    } else {
      ref.read(multiStepOnboardingProvider(role).notifier).previousStep();
    }
  }

  List<OnboardingStep> _getStepsForRole(SportXRole role) {
    return onboardingStepsForRole(role);
  }
}

// ═══════════════════════════════════════════════════════════════
// Step Content Widgets (Top-level classes)
// ═══════════════════════════════════════════════════════════════

class _CoreIdentityStep extends StatefulWidget {
  final MultiStepOnboardingNotifier notifier;
  const _CoreIdentityStep({required this.notifier});

  @override
  State<_CoreIdentityStep> createState() => _CoreIdentityStepState();
}

class _CoreIdentityStepState extends State<_CoreIdentityStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  DateTime? _dob;
  String? _gender;

  @override
  void initState() {
    super.initState();
    // Seed from stored form data so returning to this step restores prior input.
    final data = widget.notifier.progress.formData;
    _nameController = TextEditingController(text: data['full_name'] as String? ?? '');
    _phoneController = TextEditingController(text: data['phone'] as String? ?? '');
    _gender = data['gender'] as String?;
    final dobRaw = data['date_of_birth'] as String?;
    if (dobRaw != null) _dob = DateTime.tryParse(dobRaw);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  MultiStepOnboardingNotifier get notifier => widget.notifier;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about yourself',
              style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text('This helps us personalize your experience',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          
          _FormField(
            label: 'Full Name',
            hint: 'As per your ID',
            controller: _nameController,
            icon: LucideIcons.user,
            onChanged: (v) => notifier.updateFormData({'full_name': v}),
          ),
          const SizedBox(height: 16),
          
          _FormField(
            label: 'Phone Number',
            hint: '+91 XXXXX XXXXX',
            controller: _phoneController,
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
            onChanged: (v) => notifier.updateFormData({'phone': v}),
          ),
          const SizedBox(height: 16),
          
          _DatePickerField(
            label: 'Date of Birth',
            hint: 'Select date',
            initialDate: _dob,
            onChanged: (d) {
              setState(() => _dob = d);
              notifier.updateFormData({'date_of_birth': d.toIso8601String().split('T')[0]});
            },
          ),
          const SizedBox(height: 16),
          
          _DropdownField<String>(
            label: 'Gender',
            hint: 'Select',
            value: _gender,
            items: ['male', 'female']
                .map((g) => DropdownMenuItem(value: g, child: Text(g.capitalize())))
                .toList(),
            onChanged: (v) {
              setState(() => _gender = v);
              notifier.updateFormData({'gender': v});
            },
          ),
        ],
      ),
    );
  }
}

class _RoleProfileStep extends ConsumerStatefulWidget {
  final MultiStepOnboardingNotifier notifier;
  final SportXRole role;
  const _RoleProfileStep({required this.notifier, required this.role});

  @override
  ConsumerState<_RoleProfileStep> createState() => _RoleProfileStepState();
}

class _RoleProfileStepState extends ConsumerState<_RoleProfileStep> {
  int? _sportId;
  String? _skillLevel;
  int? _cityId;

  @override
  void initState() {
    super.initState();
    final data = widget.notifier.progress.formData;
    _sportId = (data['sport_id'] as num?)?.toInt();
    _skillLevel = data['skill_level'] as String?;
    _cityId = (data['city_id'] as num?)?.toInt();
  }

  MultiStepOnboardingNotifier get notifier => widget.notifier;
  SportXRole get role => widget.role;

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
    final sports = meta.sports.where((s) => s.isActive).toList();
    final cities = meta.cities.where((c) => c.isActive).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your ${role.name} Profile',
              style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text('Help others find you',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          
          if (role == SportXRole.athlete || role == SportXRole.coach) ...[
            if (meta.isLoading)
              const _FieldPlaceholder(height: 56)
            else if (sports.isEmpty)
              const _FieldPlaceholder(height: 56, message: 'No sports available right now')
            else
              _DropdownField<int>(
                label: 'Primary Sport',
                hint: 'Select your sport',
                value: _sportId,
                items: sports
                    .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: (v) {
                  setState(() => _sportId = v);
                  notifier.updateFormData({'sport_id': v});
                },
              ),
            const SizedBox(height: 16),
            _DropdownField<String>(
              label: 'Skill Level',
              hint: 'Select level',
              value: _skillLevel,
              items: ['beginner', 'intermediate', 'advanced', 'professional']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.capitalize())))
                  .toList(),
              onChanged: (v) {
                setState(() => _skillLevel = v);
                notifier.updateFormData({'skill_level': v});
              },
            ),
            const SizedBox(height: 16),
          ],
          
          if (role == SportXRole.coach) ...[
            _FormField(
              label: 'Coaching License',
              hint: 'License number & issuing body',
              icon: LucideIcons.award,
              onChanged: (v) => notifier.updateFormData({'coaching_license': v}),
            ),
            const SizedBox(height: 16),
          ],
          
          if (role == SportXRole.academy) ...[
            _FormField(
              label: 'Academy Name',
              hint: 'Official academy name',
              icon: LucideIcons.building2,
              onChanged: (v) => notifier.updateFormData({'organization_name': v}),
            ),
            const SizedBox(height: 16),
            _FormField(
              label: 'Academy License',
              hint: 'Registration number',
              icon: LucideIcons.badgeCheck,
              onChanged: (v) => notifier.updateFormData({'academy_license': v}),
            ),
            const SizedBox(height: 16),
          ],
          
          if (role == SportXRole.organizer) ...[
            _FormField(
              label: 'Organization Name',
              hint: 'Legal entity name',
              icon: LucideIcons.building2,
              onChanged: (v) => notifier.updateFormData({'organization_name': v}),
            ),
            const SizedBox(height: 16),
            _FormField(
              label: 'Tax ID / GST',
              hint: 'GSTIN or tax registration',
              icon: LucideIcons.fileText,
              onChanged: (v) => notifier.updateFormData({'tax_id': v}),
            ),
            const SizedBox(height: 16),
            _FormField(
              label: 'Website',
              hint: 'https://...',
              icon: LucideIcons.globe,
              keyboardType: TextInputType.url,
              onChanged: (v) => notifier.updateFormData({'website': v}),
            ),
            const SizedBox(height: 16),
          ],
          
          if (role == SportXRole.scout) ...[
            _FormField(
              label: 'Scouting License',
              hint: 'Certification details',
              icon: LucideIcons.badgeCheck,
              onChanged: (v) => notifier.updateFormData({'scouting_license': v}),
            ),
            const SizedBox(height: 16),
          ],
          
          if (role == SportXRole.sponsor) ...[
            _FormField(
              label: 'Company Name',
              hint: 'Registered company name',
              icon: LucideIcons.building2,
              onChanged: (v) => notifier.updateFormData({'company_name': v}),
            ),
            const SizedBox(height: 16),
            _FormField(
              label: 'Tax ID / GST',
              hint: 'GSTIN or tax registration',
              icon: LucideIcons.fileText,
              onChanged: (v) => notifier.updateFormData({'tax_id': v}),
            ),
            const SizedBox(height: 16),
          ],
          
          if (meta.isLoading)
            const _FieldPlaceholder(height: 56)
          else if (cities.isEmpty)
            const _FieldPlaceholder(height: 56, message: 'No cities available right now')
          else
            _DropdownField<int>(
            label: 'City',
            hint: 'Select your city',
            value: _cityId,
            items: cities
                .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.state.isEmpty ? c.name : '${c.name}, ${c.state}'),
                    ))
                .toList(),
            onChanged: (v) {
              setState(() => _cityId = v);
              notifier.updateFormData({'city_id': v});
            },
          ),
          const SizedBox(height: 16),
          
          _FormField(
            label: 'Bio',
            hint: 'Tell us about yourself (max 500 chars)',
            icon: LucideIcons.fileText,
            maxLines: 4,
            onChanged: (v) => notifier.updateFormData({'bio': v}),
          ),
        ],
      ),
    );
  }
}

class _MediaStep extends StatelessWidget {
  final MultiStepOnboardingNotifier notifier;
  const _MediaStep({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Photos',
              style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text('Profiles with photos get 10x more views',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          
          _MediaUploadTile(
            title: 'Profile Photo',
            subtitle: 'Clear face photo for recognition',
            icon: LucideIcons.user,
            onTap: () => notifier.updateFormData({'profile_photo_action': 'pick'}),
          ),
          const SizedBox(height: 16),
          
          _MediaUploadTile(
            title: 'Cover Photo',
            subtitle: 'Banner image for your profile',
            icon: LucideIcons.image,
            onTap: () => notifier.updateFormData({'cover_photo_action': 'pick'}),
          ),
        ],
      ),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  final MultiStepOnboardingNotifier notifier;
  const _VerificationStep({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Get Verified',
              style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text('Verified badge builds trust and unlocks features',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          
          _MediaUploadTile(
            title: 'Government ID',
            subtitle: 'Aadhaar, PAN, Passport, or Driving License',
            icon: LucideIcons.badgeCheck,
            onTap: () => notifier.updateFormData({'verification_doc_action': 'pick'}),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.info, color: AppColors.info, size: 20),
                    const SizedBox(width: 8),
                    Text('How it works', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.info)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Upload a clear photo of your government ID\n'
                  '• Our team reviews within 24-48 hours\n'
                  '• Verified badge appears on your profile\n'
                  '• Document is encrypted and deleted after verification',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.info),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferencesStep extends StatefulWidget {
  final MultiStepOnboardingNotifier notifier;
  const _PreferencesStep({required this.notifier});

  @override
  State<_PreferencesStep> createState() => _PreferencesStepState();
}

class _PreferencesStepState extends State<_PreferencesStep> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _profilePublic = true;
  bool _showActivity = true;

  @override
  void initState() {
    super.initState();
    final data = widget.notifier.progress.formData;
    bool read(String key, bool fallback) => data[key] as bool? ?? fallback;
    _pushNotifications = read('push_notifications', true);
    _emailNotifications = read('email_notifications', true);
    _smsNotifications = read('sms_notifications', false);
    _profilePublic = read('profile_public', true);
    _showActivity = read('show_activity', true);
  }

  MultiStepOnboardingNotifier get notifier => widget.notifier;

  void _set(String key, bool value) => notifier.updateFormData({key: value});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Preferences',
              style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text('Customize your experience',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          
          Text('Notifications', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 12),
          _PreferenceTile(
            title: 'Push Notifications',
            subtitle: 'Match updates, messages, opportunities',
            value: _pushNotifications,
            onChanged: (v) { setState(() => _pushNotifications = v); _set('push_notifications', v); },
          ),
          _PreferenceTile(
            title: 'Email Notifications',
            subtitle: 'Weekly digest, important updates',
            value: _emailNotifications,
            onChanged: (v) { setState(() => _emailNotifications = v); _set('email_notifications', v); },
          ),
          _PreferenceTile(
            title: 'SMS Notifications',
            subtitle: 'Critical alerts only',
            value: _smsNotifications,
            onChanged: (v) { setState(() => _smsNotifications = v); _set('sms_notifications', v); },
          ),
          const SizedBox(height: 24),
          
          Text('Privacy', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 12),
          _PreferenceTile(
            title: 'Public Profile',
            subtitle: 'Visible to other SportX users',
            value: _profilePublic,
            onChanged: (v) { setState(() => _profilePublic = v); _set('profile_public', v); },
          ),
          _PreferenceTile(
            title: 'Show Activity',
            subtitle: 'Matches, achievements, posts',
            value: _showActivity,
            onChanged: (v) { setState(() => _showActivity = v); _set('show_activity', v); },
          ),
        ],
      ),
    );
  }
}

class _CompletionStep extends StatelessWidget {
  const _CompletionStep();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFDCFCE7), Color(0xFF86EFAC)],
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.checkCircle, size: 50, color: Color(0xFF15803D)),
            ),
            const SizedBox(height: 24),
            Text('Welcome to SportX!',
                style: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 12),
            Text(
              'Your profile is set up and ready to go.\nStart exploring, connecting, and growing.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final void Function(String) onChanged;

  const _FormField({
    required this.label,
    required this.hint,
    this.controller,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppColors.textTertiary),
            prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.ink),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatefulWidget {
  final String label;
  final String hint;
  final DateTime? initialDate;
  final void Function(DateTime) onChanged;

  const _DatePickerField({
    required this.label,
    required this.hint,
    this.initialDate,
    required this.onChanged,
  });

  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<_DatePickerField> {
  late DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  void didUpdateWidget(covariant _DatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep in sync if the parent supplies a new value.
    if (widget.initialDate != oldWidget.initialDate) {
      _selectedDate = widget.initialDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _selectedDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
              widget.onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, color: AppColors.textTertiary, size: 20),
                const SizedBox(width: 12),
                Text(
                  selectedDate != null
                      ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                      : widget.hint,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: selectedDate != null ? AppColors.ink : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _DropdownField({
    required this.label,
    required this.hint,
    this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppColors.textTertiary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.ink),
          dropdownColor: Colors.white,
          icon: const Icon(LucideIcons.chevronDown, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _FieldPlaceholder extends StatelessWidget {
  final double height;
  final String message;
  const _FieldPlaceholder({required this.height, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
      ),
    );
  }
}

class _MediaUploadTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MediaUploadTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.yellowTint,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 22, color: AppColors.primaryDarker),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _PreferenceTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}