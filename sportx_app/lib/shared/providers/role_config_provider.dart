import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/role_config.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';

/// The signed-in user's role as a [SportXRole], or null when signed out.
final activeRoleProvider = Provider<SportXRole?>((ref) {
  final user = ref.watch(authProvider).user;
  return sportXRoleFromId(user?.role);
});

/// The shell configuration for the active role. Falls back to Athlete so the
/// shell (bottom nav, headers, create launcher) never renders a broken state
/// during auth transitions.
final roleConfigProvider = Provider<RoleConfig>((ref) {
  final role = ref.watch(activeRoleProvider);
  return roleConfigFor(role ?? SportXRole.athlete);
});
