import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';

class ScoutShell extends StatelessWidget {
  final Widget child;
  const ScoutShell({super.key, required this.child});

  int _indexFor(String loc) {
    if (loc.startsWith('/scout-discovery')) return 1;
    if (loc.startsWith('/scout-shortlist')) return 2;
    if (loc.startsWith('/scout-connections')) return 3;
    if (loc.startsWith('/scout-profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/scout-dashboard');
        break;
      case 1:
        context.go('/scout-discovery');
        break;
      case 2:
        context.go('/scout-shortlist');
        break;
      case 3:
        context.go('/scout-connections');
        break;
      case 4:
        context.go('/scout-profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _indexFor(loc);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: AppColors.scout.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => GoogleFonts.inter(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? AppColors.scout : AppColors.textSecondary)),
          selectedIndex: idx,
          onDestinationSelected: (i) => _onTap(context, i),
          destinations: const [
            NavigationDestination(icon: Icon(LucideIcons.home), selectedIcon: Icon(LucideIcons.home, color: AppColors.scout), label: 'Home'),
            NavigationDestination(icon: Icon(LucideIcons.search), selectedIcon: Icon(LucideIcons.search, color: AppColors.scout), label: 'Discover'),
            NavigationDestination(icon: Icon(LucideIcons.star), selectedIcon: Icon(LucideIcons.star, color: AppColors.scout), label: 'Shortlist'),
            NavigationDestination(icon: Icon(LucideIcons.users), selectedIcon: Icon(LucideIcons.users, color: AppColors.scout), label: 'Connections'),
            NavigationDestination(icon: Icon(LucideIcons.user), selectedIcon: Icon(LucideIcons.user, color: AppColors.scout), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
