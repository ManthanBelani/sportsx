import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
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
              'Tell us about you',
              style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            Text('Step 1 of 2', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
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
              child: Text('1', style: GoogleFonts.inter(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w800)),
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
                    Text('Full Name', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(LucideIcons.user, size: 18, color: AppColors.textSecondary),
                      ),
                      onChanged: (v) => ref.read(onboardingProvider.notifier).setFullName(v),
                    ),
                    const SizedBox(height: 20),

                    Text('Date of Birth', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDob,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: AppColors.border, width: 1.5),
                          boxShadow: SportXShadows.e1,
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendarDays, color: AppColors.textSecondary, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              onboarding.dateOfBirth.isEmpty ? 'Select date of birth' : onboarding.dateOfBirth,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: onboarding.dateOfBirth.isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('Gender', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _genders.map((g) {
                        final isSelected = onboarding.gender == g['value'];
                        return SportXChip(
                          label: g['label']!,
                          selected: isSelected,
                          onTap: () => ref.read(onboardingProvider.notifier).setGender(g['value']!),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    Text('Select your sport(s)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    if (meta.isLoading)
                      const Padding(padding: EdgeInsets.all(32), child: SkeletonBox(width: double.infinity, height: 48, borderRadius: 8))
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
                                color: isSelected ? AppColors.yellowSoft : AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? AppColors.yellowDeep : AppColors.border, width: isSelected ? 1.5 : 1),
                                boxShadow: SportXShadows.e1,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_getSportIcon(sport.name), color: isSelected ? AppColors.primaryDarker : AppColors.textSecondary, size: 30),
                                  const SizedBox(height: 8),
                                  Text(
                                    sport.name,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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

                    Text('Age category', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: meta.ageGroups.map((group) {
                        final isSelected = onboarding.selectedAgeGroupId == group.id;
                        return SportXChip(
                          label: group.label,
                          selected: isSelected,
                          onTap: () => ref.read(onboardingProvider.notifier).setAgeGroup(group.id),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(color: AppColors.cardBackground, border: Border(top: BorderSide(color: AppColors.border))),
              child: SafeArea(
                top: false,
                child: Opacity(
                  opacity: canContinue ? 1.0 : 0.5,
                  child: PrimaryButton(
                    label: 'Continue',
                    icon: LucideIcons.arrowRight,
                    onPressed: canContinue ? () => context.push('/onboarding-2') : null,
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
