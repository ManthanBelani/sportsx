import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class OnboardingSkillLocationScreen extends ConsumerStatefulWidget {
  const OnboardingSkillLocationScreen({super.key});

  @override
  ConsumerState<OnboardingSkillLocationScreen> createState() => _OnboardingSkillLocationScreenState();
}

class _OnboardingSkillLocationScreenState extends ConsumerState<OnboardingSkillLocationScreen> {
  String _selectedSkill = 'intermediate';
  int? _selectedCityId;
  String? _selectedState;
  bool _isSubmitting = false;

  final _skills = [
    {'value': 'beginner', 'label': 'Beginner'},
    {'value': 'intermediate', 'label': 'Intermediate'},
    {'value': 'advanced', 'label': 'Advanced'},
    {'value': 'competitive', 'label': 'Competitive'},
  ];

  Future<void> _finish() async {
    if (_selectedCityId == null) return;

    ref.read(onboardingProvider.notifier).setSkillLevel(_selectedSkill);
    ref.read(onboardingProvider.notifier).setCity(_selectedCityId!);

    setState(() => _isSubmitting = true);

    final success = await ref.read(onboardingProvider.notifier).submitAthleteOnboarding();

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ref.read(authProvider.notifier).markOnboardingComplete();
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
    final onboarding = ref.watch(onboardingProvider);
    final canSubmit = _selectedCityId != null && !_isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Location & Skill',
              style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Step 2 of 2',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFD54A), Color(0xFFFFC107), Color(0xFFF5B400)],
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('2', style: GoogleFonts.inter(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Skill Level', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _skills.map((skill) {
                        final isSelected = _selectedSkill == skill['value'];
                        return SportXChip(
                          label: skill['label'] as String,
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedSkill = skill['value'] as String;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    GestureDetector(
                      onTap: () {
                        SnackBarUtils.showInfo(context, 'Location detection will be available in a future update. Please select your city manually.');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.yellowSoft,
                          border: Border.all(color: AppColors.yellowDeep, width: 1.5),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: SportXShadows.e1,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.yellow.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(LucideIcons.satellite, color: AppColors.primaryDarker, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Detect my location', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  Text('Use GPS for accurate results', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, color: AppColors.textTertiary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Select your state', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Builder(builder: (context) {
                      final states = meta.cities.map((c) => c.state).toSet().toList()..sort();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          border: Border.all(color: AppColors.border, width: 1.5),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: SportXShadows.e1,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedState,
                            hint: Text('Choose state', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary)),
                            icon: const Icon(LucideIcons.chevronDown, color: AppColors.textSecondary, size: 20),
                            items: states.map((s) {
                              return DropdownMenuItem<String>(
                                value: s,
                                child: Text(s, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedState = value;
                                // Reset city when state changes if city not in state
                                if (_selectedCityId != null) {
                                  final city = meta.cities.where((c) => c.id == _selectedCityId).firstOrNull;
                                  if (city != null && city.state != value) _selectedCityId = null;
                                }
                              });
                            },
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    Text('Select your city', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    if (meta.isLoading)
                      const Padding(padding: EdgeInsets.all(32), child: SkeletonBox(width: double.infinity, height: 48, borderRadius: 8))
                    else
                      Builder(builder: (context) {
                        final filteredCities = _selectedState == null
                            ? meta.cities
                            : meta.cities.where((c) => c.state == _selectedState).toList();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            border: Border.all(color: AppColors.border, width: 1.5),
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: SportXShadows.e1,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: _selectedCityId,
                              hint: Text('Choose city', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary)),
                              icon: const Icon(LucideIcons.chevronDown, color: AppColors.textSecondary, size: 20),
                              items: filteredCities.map((city) {
                                return DropdownMenuItem<int>(
                                  value: city.id,
                                  child: Text('${city.name}, ${city.state}', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCityId = value;
                                });
                              },
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 24),
                    Text('Popular cities', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    if (!meta.isLoading)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Chennai', 'Kolkata', 'Ahmedabad', 'Pune'].map((cityName) {
                          // Find city by name
                          final cityMatches = meta.cities.where((c) => c.name.toLowerCase() == cityName.toLowerCase());
                          if (cityMatches.isEmpty) return const SizedBox.shrink();

                          final city = cityMatches.first;
                          final isSelected = _selectedCityId == city.id;

                          return SportXChip(
                            label: cityName,
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedCityId = city.id;
                                _selectedState = city.state;
                              });
                            },
                          );
                        }).toList(),
                      ),

                    if (onboarding.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(onboarding.error!, style: GoogleFonts.inter(color: AppColors.error, fontSize: 13)),
                      ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: _isSubmitting
                    ? Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFD54A), Color(0xFFFFC107), Color(0xFFF5B400)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x2E785000)),
                          boxShadow: SportXShadows.btnShadow,
                        ),
                        alignment: Alignment.center,
                        child: const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2)),
                      )
                    : Opacity(
                        opacity: canSubmit ? 1.0 : 0.5,
                        child: PrimaryButton(
                          label: 'Continue',
                          icon: LucideIcons.arrowRight,
                          onPressed: canSubmit ? _finish : null,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
