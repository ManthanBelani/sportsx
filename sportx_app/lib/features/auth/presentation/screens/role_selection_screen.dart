import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  void _handleContinue() {
    if (_selectedRole != null) {
      context.push('/sign-up', extra: {'role': _selectedRole});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Text(
                'Who are you joining as?',
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your role to get started',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _RoleCard(
                      id: 'athlete',
                      title: 'Athlete / Parent',
                      subtitle: 'Find academies, coaches, trials & more',
                      iconData: LucideIcons.user,
                      iconBgColor: AppColors.yellowTint,
                      iconColor: AppColors.warnText,
                      isSelected: _selectedRole == 'athlete',
                      onTap: () => setState(() => _selectedRole = 'athlete'),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      id: 'coach',
                      title: 'Coach',
                      subtitle: 'List your coaching services',
                      iconData: LucideIcons.clipboardList,
                      iconBgColor: AppColors.coach.withValues(alpha: 0.12),
                      iconColor: AppColors.coach,
                      isSelected: _selectedRole == 'coach',
                      onTap: () => setState(() => _selectedRole = 'coach'),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      id: 'academy',
                      title: 'Academy',
                      subtitle: 'Manage your academy & trials',
                      iconData: LucideIcons.building2,
                      iconBgColor: AppColors.successLight,
                      iconColor: AppColors.academy,
                      isSelected: _selectedRole == 'academy',
                      onTap: () => setState(() => _selectedRole = 'academy'),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      id: 'organizer',
                      title: 'Organizer',
                      subtitle: 'Post tournaments & manage events',
                      iconData: LucideIcons.calendarDays,
                      iconBgColor: AppColors.organizer.withValues(alpha: 0.12),
                      iconColor: AppColors.organizer,
                      isSelected: _selectedRole == 'organizer',
                      onTap: () => setState(() => _selectedRole = 'organizer'),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      id: 'sponsor',
                      title: 'Sponsor / Brand',
                      subtitle: 'Find & sponsor athletes',
                      iconData: LucideIcons.briefcase,
                      iconBgColor: AppColors.pink.withValues(alpha: 0.12),
                      iconColor: AppColors.pink,
                      isSelected: _selectedRole == 'sponsor',
                      onTap: () => setState(() => _selectedRole = 'sponsor'),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      id: 'talent_scout',
                      title: 'Talent Scout',
                      subtitle: 'Discover & shortlist promising athletes',
                      iconData: LucideIcons.userSearch,
                      iconBgColor: AppColors.infoLight,
                      iconColor: AppColors.scout,
                      isSelected: _selectedRole == 'talent_scout',
                      onTap: () => setState(() => _selectedRole = 'talent_scout'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      'Log in',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.primaryDarker,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SizedBox(
                    width: double.infinity,
                    child: Opacity(
                      opacity: _selectedRole != null ? 1.0 : 0.5,
                      child: PrimaryButton(
                        label: 'Continue',
                        icon: LucideIcons.arrowRight,
                        onPressed: _selectedRole != null ? _handleContinue : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final IconData iconData;
  final Color iconBgColor;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.iconBgColor,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.yellowSoft : AppColors.cardBackground,
          border: Border.all(
            color: isSelected ? AppColors.yellowDeep : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? LucideIcons.circleCheck : LucideIcons.chevronRight,
              color: isSelected ? AppColors.yellowDeep : AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
