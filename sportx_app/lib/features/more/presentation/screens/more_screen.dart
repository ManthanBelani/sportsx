import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/role_config.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/athlete/presentation/providers/achievements_provider.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/connections_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/shared/providers/role_config_provider.dart';
import 'package:sportx_app/shared/providers/providers.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/theme/design_tokens.dart';

/// S.15 More / account hub. Shared shell screen: the summary card and the row
/// list are driven entirely by [roleConfigProvider], so every role reuses this
/// one screen and only its data differs — the athlete role additionally gets
/// the design's stathead + row3 KPI module.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(roleConfigProvider);
    final user = ref.watch(authProvider).user;
    final rows = [...config.moreRows];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SportXTopBar(title: 'More'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Center(
            child: Text('Manage • Explore • Get Support',
                style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 12),
          if (config.role == SportXRole.athlete)
            _AthleteStatHead(
              name: user?.name ?? 'Guest',
              roleLabel: config.label,
              photoUrl: user?.profilePhotoUrl ?? '',
              isVerified: user?.isVerified ?? false,
              onTap: () => context.push(config.profileRoute),
            )
          else
            _ProfileCard(
              name: user?.name ?? 'Guest',
              roleLabel: config.label,
              photoUrl: user?.profilePhotoUrl ?? '',
              isVerified: user?.isVerified ?? false,
              onTap: () => context.push(config.profileRoute),
            ),
          const SizedBox(height: 12),
          for (final row in rows) _MoreTile(row: row),
          const SizedBox(height: 6),
          _LogoutTile(onTap: () => _confirmLogout(context, ref)),
          const SizedBox(height: 10),
          Center(
            child: Text('Let\'s Defeat History • SportX India',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log out?', style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text('You will need to sign in again.', style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

// ─── Athlete stathead (design S.15 athlete variant) ──────────────────────────

class _AthleteStatHead extends ConsumerWidget {
  final String name;
  final String roleLabel;
  final String photoUrl;
  final bool isVerified;
  final VoidCallback onTap;

  const _AthleteStatHead({
    required this.name,
    required this.roleLabel,
    required this.photoUrl,
    required this.isVerified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final connections = ref.watch(connectionCountProvider);
    final achievements = ref.watch(achievementsProvider);
    final city = profile.maybeWhen(
      data: (p) {
        if (p == null) return '';
        return (p['city'] != null && (p['city'] as Map?)?['name']?.toString().isNotEmpty == true)
            ? (p['city'] as Map)['name'].toString()
            : '';
      },
      orElse: () => '',
    );
    final complete = profile.maybeWhen(
      data: (p) {
        if (p == null) return null;
        final keys = ['bio', 'profile_photo_url', 'sport_id', 'date_of_birth', 'city_id'];
        final filled = keys.where((k) => (p[k]?.toString() ?? '').isNotEmpty).length;
        return (filled / keys.length * 100).round();
      },
      orElse: () => null,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: SportXShadows.e1,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar64(url: photoUrl, initial: name.isNotEmpty ? name[0].toUpperCase() : '?'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 5),
                          Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: const Icon(LucideIcons.check, size: 9, color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(roleLabel, style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary)),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 10, color: AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(city.isNotEmpty ? city : roleLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('View Profile ›',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.dark)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _kpi(connections.maybeWhen(data: (n) => n, orElse: () => null), 'Connections'),
                _divider(),
                _kpi(achievements.maybeWhen(data: (n) => n.length, orElse: () => null), 'Achievements'),
                _divider(),
                _kpi(complete, 'Profile %', suffix: complete != null ? '%' : null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _dividerColor = Color(0xFFE8EAED);

  Widget _divider() => Container(width: 1, height: 26, color: _dividerColor);

  Widget _kpi(int? n, String label, {String? suffix}) {
    return Expanded(
      child: Column(
        children: [
          Text(n == null ? '—' : '$n${suffix ?? ''}',
              style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Avatar64 extends StatelessWidget {
  final String url;
  final String initial;
  const _Avatar64({required this.url, required this.initial});

  @override
  Widget build(BuildContext context) {
    final has = url.trim().isNotEmpty;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.yellowTint,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: AppColors.yellow.withValues(alpha: 0.55), spreadRadius: 2, blurRadius: 0)],
        image: has
            ? DecorationImage(
                image: NetworkImage(MediaUtils.resolveUrl(url)),
                fit: BoxFit.cover,
                onError: (_, _) {},
              )
            : null,
      ),
      alignment: Alignment.center,
      child: has ? null : Text(initial, style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryDarker)),
    );
  }
}

// ─── Non-athlete profile summary ─────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String name;
  final String roleLabel;
  final String photoUrl;
  final bool isVerified;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.name,
    required this.roleLabel,
    required this.photoUrl,
    required this.isVerified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          boxShadow: SportXShadows.e1,
        ),
        child: Row(
          children: [
            _Avatar64(url: photoUrl, initial: initial),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.sora(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 5),
                        const Icon(LucideIcons.badgeCheck, size: 15, color: AppColors.success),
                      ],
                    ],
                  ),
                  Text(roleLabel, style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary)),
                  Text('View Profile ›',
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryDarker)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Color(0xFFC9CDD3), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Rows (v3 .mrow with tinted icon square + subtitle) ──────────────────────

class _MoreTile extends StatelessWidget {
  final MoreRow row;
  const _MoreTile({required this.row});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(row.route),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: row.tintBg, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Icon(row.icon, size: 19, color: row.tintFg),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.label,
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  if (row.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(row.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 9.5, height: 1.35, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Color(0xFFC9CDD3), size: 18),
          ],
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          border: Border.all(color: const Color(0x40EF4444)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFFDE8E8), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFB91C1C)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Logout', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))),
                  Text('Sign out from your account',
                      style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Color(0xFFC9CDD3), size: 18),
          ],
        ),
      ),
    );
  }
}
