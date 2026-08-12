import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class OnboardingSportAgeScreen extends ConsumerStatefulWidget {
  const OnboardingSportAgeScreen({super.key});

  @override
  ConsumerState<OnboardingSportAgeScreen> createState() => _OnboardingSportAgeScreenState();
}

class _OnboardingSportAgeScreenState extends ConsumerState<OnboardingSportAgeScreen> {
  final _nameController = TextEditingController();

  static const _genders = [
    {'value': 'male', 'label': 'Male'},
    {'value': 'female', 'label': 'Female'},
    {'value': 'other', 'label': 'Other'},
    {'value': 'prefer_not_to_say', 'label': 'Prefer not to say'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  IconData _getSportIcon(String sportName) {
    final lower = sportName.toLowerCase();
    if (lower.contains('cricket')) return LucideIcons.circleDot;
    if (lower.contains('football')) return LucideIcons.goal;
    if (lower.contains('badminton')) return LucideIcons.circleDot;
    if (lower.contains('swimming')) return LucideIcons.waves;
    if (lower.contains('athletics')) return LucideIcons.footprints;
    if (lower.contains('tennis')) return LucideIcons.circle;
    if (lower.contains('basketball')) return LucideIcons.circle;
    if (lower.contains('kabaddi')) return LucideIcons.hand;
    return LucideIcons.plus;
  }

  Future<void> _pickDob() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(today.year - 14),
      firstDate: DateTime(1950),
      lastDate: today,
    );
    if (picked != null) {
      ref.read(onboardingProvider.notifier).setDateOfBirth(
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
    final onboarding = ref.watch(onboardingProvider);

    // Keep the controller in sync with provider state (e.g. on back-nav).
    if (_nameController.text != onboarding.fullName) {
      _nameController.text = onboarding.fullName;
      _nameController.selection = TextSelection.fromPosition(TextPosition(offset: _nameController.text.length));
    }

    final canContinue = onboarding.fullName.trim().isNotEmpty &&
        onboarding.dateOfBirth.isNotEmpty &&
        onboarding.gender.isNotEmpty &&
        onboarding.selectedSportIds.isNotEmpty &&
        onboarding.selectedAgeGroupId != null;

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
              'Tell us about you',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const Text('Step 1 of 2', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
                    const Text('Full Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration('Enter your full name'),
                      onChanged: (v) => ref.read(onboardingProvider.notifier).setFullName(v),
                    ),
                    const SizedBox(height: 20),

                    const Text('Date of Birth', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDob,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendar, color: AppColors.textSecondary, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              onboarding.dateOfBirth.isEmpty ? 'Select date of birth' : onboarding.dateOfBirth,
                              style: TextStyle(
                                fontSize: 15,
                                color: onboarding.dateOfBirth.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Gender', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _genders.map((g) {
                        final isSelected = onboarding.gender == g['value'];
                        return GestureDetector(
                          onTap: () => ref.read(onboardingProvider.notifier).setGender(g['value']!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              g['label']!,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppColors.textPrimary),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    const Text('Select your sport(s)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    if (meta.isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: meta.sports.length,
                        itemBuilder: (context, index) {
                          final sport = meta.sports[index];
                          final isSelected = onboarding.selectedSportIds.contains(sport.id);
                          return GestureDetector(
                            onTap: () {
                              final current = Set<int>.from(onboarding.selectedSportIds);
                              if (isSelected) {
                                current.remove(sport.id);
                              } else {
                                current.add(sport.id);
                              }
                              ref.read(onboardingProvider.notifier).setSports(current);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFE6F0FF) : AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_getSportIcon(sport.name), color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    sport.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),

                    const Text('Age category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: meta.ageGroups.map((group) {
                        final isSelected = onboarding.selectedAgeGroupId == group.id;
                        return GestureDetector(
                          onTap: () => ref.read(onboardingProvider.notifier).setAgeGroup(group.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              group.label,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppColors.textPrimary),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: AppColors.border))),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: canContinue ? () => context.push('/onboarding-2') : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
    );
  }
}
