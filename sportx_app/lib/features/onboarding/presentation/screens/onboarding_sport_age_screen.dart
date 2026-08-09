import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class OnboardingSportAgeScreen extends ConsumerWidget {
  const OnboardingSportAgeScreen({super.key});

  IconData _getSportIcon(String sportName) {
    final lower = sportName.toLowerCase();
    if (lower.contains('cricket')) return LucideIcons.circleDot;
    if (lower.contains('football')) return LucideIcons.goal;
    if (lower.contains('badminton')) return LucideIcons.shuttlecock;
    if (lower.contains('swimming')) return LucideIcons.waves;
    if (lower.contains('athletics')) return LucideIcons.footprints;
    if (lower.contains('tennis')) return LucideIcons.circle;
    if (lower.contains('basketball')) return LucideIcons.circle;
    if (lower.contains('kabaddi')) return LucideIcons.hand;
    return LucideIcons.plus;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ref.watch(metaProvider);
    final onboarding = ref.watch(onboardingProvider);

    final canContinue = onboarding.selectedSportIds.isNotEmpty && onboarding.selectedAgeGroupId != null;

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
              'Your Sport & Age',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Step 1 of 2',
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
                    const Text('Select your primary sport', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
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
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getSportIcon(sport.name),
                                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    sport.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? AppColors.textPrimary : AppColors.textPrimary,
                                    ),
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
                    if (meta.isLoading)
                      const SizedBox.shrink()
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: meta.ageGroups.map((group) {
                          final isSelected = onboarding.selectedAgeGroupId == group.id;
                          return GestureDetector(
                            onTap: () {
                              ref.read(onboardingProvider.notifier).setAgeGroup(group.id);
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
                                group.label,
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
}
