import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Text(
                'Who are you joining as?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your role to get started',
                style: TextStyle(
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
                      iconBgColor: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFF92400E),
                      isSelected: _selectedRole == 'athlete',
                      onTap: () => setState(() => _selectedRole = 'athlete'),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      id: 'coach',
                      title: 'Coach',
                      subtitle: 'List your coaching services',
                      iconData: LucideIcons.clipboardList,
                      iconBgColor: const Color(0xFFDBEAFE),
                      iconColor: const Color(0xFF1E40AF),
                      isSelected: _selectedRole == 'coach',
                      onTap: () => setState(() => _selectedRole = 'coach'),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      id: 'academy',
                      title: 'Academy',
                      subtitle: 'Manage your academy & trials',
                      iconData: LucideIcons.building2,
                      iconBgColor: const Color(0xFFD1FAE5),
                      iconColor: const Color(0xFF065F46),
                      isSelected: _selectedRole == 'academy',
                      onTap: () => setState(() => _selectedRole = 'academy'),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      id: 'organizer',
                      title: 'Organizer',
                      subtitle: 'Post tournaments & manage events',
                      iconData: LucideIcons.calendar,
                      iconBgColor: const Color(0xFFEDE9FE),
                      iconColor: const Color(0xFF5B21B6),
                      isSelected: _selectedRole == 'organizer',
                      onTap: () => setState(() => _selectedRole = 'organizer'),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      id: 'sponsor',
                      title: 'Sponsor / Brand',
                      subtitle: 'Find & sponsor athletes',
                      iconData: LucideIcons.briefcase,
                      iconBgColor: const Color(0xFFFCE7F3),
                      iconColor: const Color(0xFF9D174D),
                      isSelected: _selectedRole == 'sponsor',
                      onTap: () => setState(() => _selectedRole = 'sponsor'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectedRole != null ? _handleContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.border,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
          color: isSelected ? const Color(0xFFE6F0FF) : AppColors.background,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(8),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
