import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.home), selectedIcon: Icon(LucideIcons.home, color: AppColors.primary), label: 'Home'),
          NavigationDestination(icon: Icon(LucideIcons.search), selectedIcon: Icon(LucideIcons.search, color: AppColors.primary), label: 'Discover'),
          NavigationDestination(icon: Icon(LucideIcons.star), selectedIcon: Icon(LucideIcons.star, color: AppColors.primary), label: 'Shortlist'),
          NavigationDestination(icon: Icon(LucideIcons.users), selectedIcon: Icon(LucideIcons.users, color: AppColors.primary), label: 'Connections'),
          NavigationDestination(icon: Icon(LucideIcons.user), selectedIcon: Icon(LucideIcons.user, color: AppColors.primary), label: 'Profile'),
        ],
      ),
    );
  }
}
