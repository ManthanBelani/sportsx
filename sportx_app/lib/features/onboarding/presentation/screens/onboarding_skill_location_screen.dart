import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class OnboardingSkillLocationScreen extends ConsumerStatefulWidget {
  const OnboardingSkillLocationScreen({super.key});

  @override
  ConsumerState<OnboardingSkillLocationScreen> createState() => _OnboardingSkillLocationScreenState();
}

class _OnboardingSkillLocationScreenState extends ConsumerState<OnboardingSkillLocationScreen> {
  String _selectedSkill = 'intermediate';
  int? _selectedCityId;
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 24),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Location & Skill',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Step 2 of 2',
              style: TextStyle(
                fontSize: 13,
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
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
                    const Text('Skill Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _skills.map((skill) {
                        final isSelected = _selectedSkill == skill['value'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSkill = skill['value'] as String;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              skill['label'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    
                    GestureDetector(
                      onTap: () {
                        // Find Ahmedabad or Mumbai to mock location detect
                        final city = meta.cities.firstWhere((c) => c.name == 'Ahmedabad', orElse: () => meta.cities.first);
                        setState(() {
                          _selectedCityId = city.id;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F0FF),
                          border: Border.all(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.satellite, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Detect my location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                  const Text('Use GPS for accurate results', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('Select your city', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    if (meta.isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedCityId,
                            hint: const Text('Choose city', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                            icon: const Icon(LucideIcons.chevronDown, color: AppColors.textSecondary, size: 20),
                            items: meta.cities.map((city) {
                              return DropdownMenuItem<int>(
                                value: city.id,
                                child: Text('${city.name}, ${city.state}', style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCityId = value;
                              });
                            },
                          ),
                        ),
                      ),
                      
                    const SizedBox(height: 24),
                    const Text('Popular cities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
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
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCityId = city.id;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.surface,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                cityName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                    if (onboarding.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(onboarding.error!, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: (_selectedCityId != null && !_isSubmitting) ? _finish : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
