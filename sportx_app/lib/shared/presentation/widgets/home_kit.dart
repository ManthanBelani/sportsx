import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/social/presentation/providers/posts_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/leaderboard_provider.dart';
import 'package:sportx_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:sportx_app/shared/providers/role_config_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

/// v3 design kit — pixel-mapped from sportsx-design-v3/v2/index.html (the
/// Stitch "Remix of SX new Design" prototype). Shared chrome used by every
/// role's Home tab and the shell tabs (AT.1 / CO.2 / AC.2 / OR.2 / SC.2).
/// Pure presentation: no routes or providers except the leaderboard strip.

// ─────────────────────────────────────────────────────────────────────────────
// Wordmark + header actions
// ─────────────────────────────────────────────────────────────────────────────

/// .logo — "SportX" Sora 800 with yellow dot + "LET'S DEFEAT HISTORY" tagline.
class SportXWordmark extends StatelessWidget {
  const SportXWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text.rich(
            TextSpan(
              text: 'Sport',
              style: GoogleFonts.sora(
                  fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -1.2),
              children: const [
                TextSpan(text: 'X', style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
          ),
        ]),
        const SizedBox(height: 1),
        Text("Let's Defeat History",
            style: GoogleFonts.inter(
                fontSize: 7, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 1.1)),
      ],
    );
  }
}

/// .top-actions — message + bell(unread count) + avatar, shared by all home tabs.
/// The bell badge is driven by [notificationsProvider]'s unreadCount so it stays
/// in sync with mark-as-read / mark-all-read and push-triggered refreshes.
class HomeHeaderActions extends ConsumerStatefulWidget {
  final String? role;
  const HomeHeaderActions({super.key, this.role});

  @override
  ConsumerState<HomeHeaderActions> createState() => _HomeHeaderActionsState();
}

class _HomeHeaderActionsState extends ConsumerState<HomeHeaderActions>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-sync the badge when the app comes back to the foreground.
      ref.read(notificationsProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(
        notificationsProvider.select((state) => state.unreadCount));
    return Row(children: [
      SportXIconButton(icon: LucideIcons.messageCircle, onTap: () => context.push('/chat-list')),
      const SizedBox(width: 7),
      SportXIconButton(
        icon: LucideIcons.bell,
        badge: unreadCount > 0
            ? (unreadCount > 99 ? 99 : unreadCount)
            : null,
        onTap: () async {
          // Refresh so the badge and list reflect the server on open.
          ref.read(notificationsProvider.notifier).load();
          await context.push('/notifications');
          // And again when returning home, in case it changed in between.
          ref.read(notificationsProvider.notifier).load();
        },
      ),
      const SizedBox(width: 7),
      const _HeaderAvatar(),
    ]);
  }
}

class _HeaderAvatar extends ConsumerWidget {
  const _HeaderAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    // Every role has its own profile screen; pushing the athlete-only
    // '/profile' for a coach was bounced back to the dashboard by the router.
    final profileRoute = ref.watch(roleConfigProvider).profileRoute;
    final photo = user?.profilePhotoUrl;
    final initial = (user?.name.trim().isNotEmpty ?? false) ? user!.name.trim()[0].toUpperCase() : 'A';
    return GestureDetector(
      onTap: () => context.push(profileRoute),
      child: Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.fromBorderSide(BorderSide(color: AppColors.yellow, width: 2)),
        ),
        alignment: Alignment.center,
        child: ClipOval(
          child: (photo != null && photo.isNotEmpty)
              ? Image.network(MediaUtils.resolveUrl(photo),
                  width: 30, height: 30, fit: BoxFit.cover, errorBuilder: (_, _, _) => _initial(initial))
              : _initial(initial),
        ),
      ),
    );
  }

  Widget _initial(String initial) => Container(
        width: 30,
        height: 30,
        color: AppColors.yellowTint,
        alignment: Alignment.center,
        child: Text(initial,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Greet card (v3) + role line
// ─────────────────────────────────────────────────────────────────────────────

/// .greet-card — avatar, greeting, subtitle, progress bar, right-side % +
/// "Complete Now" compact CTA. OR.2 variant has no CTA (chevron instead).
class GreetCardV3 extends StatelessWidget {
  final String greeting;
  final String name;
  final String subtitle;
  final double progress;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final bool chevron;
  final String? avatarUrl;
  final String avatarInitial;
  final VoidCallback? onTap;

  const GreetCardV3({
    super.key,
    required this.greeting,
    required this.name,
    required this.subtitle,
    required this.progress,
    this.ctaLabel,
    this.onCta,
    this.chevron = false,
    this.avatarUrl,
    this.avatarInitial = 'S',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    Widget avatar = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.yellowTint,
        border: Border.all(color: AppColors.yellow, width: 2),
      ),
      alignment: Alignment.center,
      child: (avatarUrl != null && avatarUrl!.isNotEmpty)
          ? ClipOval(
              child: Image.network(MediaUtils.resolveUrl(avatarUrl!),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Text(avatarInitial,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink))),
            )
          : Text(avatarInitial,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
    );

    final body = Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFFFFCF0)]),
        border: Border.all(color: const Color(0xFFF0E3B2)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: SportXShadows.e1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          avatar,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary)),
                const SizedBox(height: 7),
                ProgressLine(progress: progress),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$pct%',
                  style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
              if (chevron) ...[
                const SizedBox(height: 6),
                const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
              ] else if (ctaLabel != null) ...[
                const SizedBox(height: 6),
                CompactPrimaryButton(label: ctaLabel!, onTap: onCta),
              ],
            ],
          ),
        ],
      ),
    );

    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: body);
  }
}

/// .progress — 6px rounded bar with yellow fill.
class ProgressLine extends StatelessWidget {
  final double progress;
  const ProgressLine({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: const BoxDecoration(color: Color(0xFFEDEFF2), borderRadius: BorderRadius.all(Radius.circular(99))),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: progress.clamp(0.02, 1.0),
        child: Container(
          decoration: const BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.all(Radius.circular(99))),
        ),
      ),
    );
  }
}

/// .primary.primary-compact — 30px tall gradient pill.
class CompactPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const CompactPrimaryButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFD54A), AppColors.yellow, Color(0xFFF5B400)]),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0x2E785000)),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
        ),
      ),
    );
  }
}

/// .role-line — role badge + city.
class RoleLine extends StatelessWidget {
  final String badgeLabel;
  final String? location;
  const RoleLine({super.key, required this.badgeLabel, this.location});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 23,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.yellowTint, borderRadius: BorderRadius.circular(99)),
          child: Text(badgeLabel.toUpperCase(),
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryDarker)),
        ),
        if (location != null && location!.isNotEmpty) ...[
          const SizedBox(width: 8),
          Icon(LucideIcons.mapPin, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 3),
          Text(location!,
              style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header (v3) + leaderboard strip
// ─────────────────────────────────────────────────────────────────────────────

/// .section-head — Sora 700 16 + "see all" pill.
class SectionHeadV3 extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  const SectionHeadV3({super.key, required this.title, this.actionText, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
            Flexible(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: SportXShadows.e1,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(actionText!,
                      style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  const SizedBox(width: 3),
                  const Icon(LucideIcons.chevronRight, size: 13, color: AppColors.textSecondary),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

/// v3 leaderboard — sport chips + top-5 avatar strip (AT.1 .strip5).
class LeaderboardSectionV3 extends ConsumerWidget {
  const LeaderboardSectionV3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strip = ref.watch(leaderboardStripProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeadV3(
            title: '🏆 Leaderboard', actionText: 'View all', onActionTap: () => context.push('/leaderboard')),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              const SportXChip(label: 'All Sports', selected: true, icon: LucideIcons.trophy),
              const SizedBox(width: 7),
              for (final s in const ['Cricket', 'Football', 'Throwball', 'Badminton', 'Athletics', 'Kabaddi'])
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: SportXChip(
                      label: s,
                      onTap: () => context.push('/leaderboard')),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        strip.when(
          loading: () => const SizedBox(height: 96),
          error: (_, _) => const SizedBox.shrink(),
          data: (rows) {
            if (rows.isEmpty) {
              return Container(
                height: 74,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: SportXShadows.e1,
                ),
                child: Text('Points live here — earn them with achievements, events and activity.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              );
            }
            return SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rows.take(10).length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final e = rows[i];
                  return _LbTile(entry: e);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LbTile extends StatelessWidget {
  final LeaderboardEntry entry;
  const _LbTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final initial = entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : 'A';
    return GestureDetector(
      onTap: () => context.push('/view-profile',
          extra: {'type': 'athlete', 'id': entry.athleteProfileId}),
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
          boxShadow: SportXShadows.e1,
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.yellowTint,
                    border: Border.all(color: AppColors.yellow, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: GoogleFonts.inter(
                          fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ),
                Positioned(
                  left: -4,
                  top: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AppColors.yellow,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5)),
                    child: Text('${entry.rank}',
                        style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(entry.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 1),
            Text('${entry.points} pts',
                style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick tiles (v3) with sub-tiles
// ─────────────────────────────────────────────────────────────────────────────

/// .quick-grid .quick-tile — icon, title, subtitle and a sub-tile grid.
class QuickTileV3 extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final VoidCallback? onTap;
  final List<({String label, String route})> subtiles;

  const QuickTileV3({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    this.onTap,
    this.subtiles = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: SportXShadows.e1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, size: 19, color: iconFg),
              ),
              const SizedBox(height: 8),
              Text(title,
                  maxLines: 2,
                  style: GoogleFonts.sora(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.25)),
              const SizedBox(height: 3),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary, height: 1.35)),
            ]),
          ),
          if (subtiles.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Sub-tiles are laid out as rows of two equal columns so the card
            // can size to its content (no leftover white space at the bottom).
            for (var i = 0; i < subtiles.length; i += 2)
              Padding(
                padding: EdgeInsets.only(bottom: i + 2 < subtiles.length ? 6 : 0),
                child: Row(
                  children: [
                    Expanded(child: _subTile(context, subtiles[i])),
                    const SizedBox(width: 6),
                    Expanded(
                      child: i + 1 < subtiles.length
                          ? _subTile(context, subtiles[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _subTile(BuildContext context, ({String label, String route}) s) {
    return GestureDetector(
      onTap: () => context.push(s.route),
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderSoft),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(s.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed tabs + shared post card
// ─────────────────────────────────────────────────────────────────────────────

/// .feedtabs — For You / Following / Athletes / Coaches / Academies / Events.
class FeedTabsBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int>? onChanged;
  const FeedTabsBar({super.key, this.activeIndex = 0, this.onChanged});

  static const labels = ['For You', 'Following', 'Athletes', 'Coaches', 'Academies', 'Events'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        padding: EdgeInsets.zero,
        itemBuilder: (_, i) {
          final active = i == activeIndex;
          return GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: active ? AppColors.yellow : Colors.transparent, width: 2)),
              ),
              child: Text(labels[i],
                  style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: active ? AppColors.ink : AppColors.textSecondary)),
            ),
          );
        },
      ),
    );
  }
}

/// .feed-card — shared community post card used by every Home tab.
class PostCardV3 extends StatelessWidget {
  final String author;
  final String authorSub;
  final String? authorAvatar;
  final String? body;
  final List<String> images;
  final DateTime? createdAt;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final int likesCount;
  final int commentsCount;
  final VoidCallback? onTap;
  final VoidCallback? onSave;

  const PostCardV3({
    super.key,
    required this.author,
    this.authorSub = '',
    this.authorAvatar,
    this.body,
    this.images = const [],
    this.createdAt,
    this.onLike,
    this.onComment,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.onTap,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _Avatar(url: authorAvatar, initial: author.isNotEmpty ? author[0].toUpperCase() : 'U', size: 36),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  if (authorSub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(authorSub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
                  ],
                ]),
              ),
              const Icon(LucideIcons.ellipsisVertical, size: 16, color: AppColors.textTertiary),
            ]),
            if (body != null && body!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(body!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11.5, height: 1.45, color: AppColors.dark)),
            ],
            if (images.isNotEmpty) ...[
              const SizedBox(height: 10),
              _imageGrid(),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                _feedAction(LucideIcons.heart, '$likesCount', onLike),
                const SizedBox(width: 18),
                _feedAction(LucideIcons.messageCircle, '$commentsCount', onComment),
                const SizedBox(width: 18),
                _feedAction(LucideIcons.share2, '', onTap),
                const Spacer(),
                GestureDetector(onTap: onSave, child: const Icon(LucideIcons.bookmark, size: 15, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageGrid() {
    if (images.length == 1) {
      return _netImage(images.first, height: 155, radius: 12);
    }
    if (images.length == 2) {
      return Row(children: [
        Expanded(flex: 14, child: _netImage(images[0], height: 150, radius: 12)),
        const SizedBox(width: 6),
        Expanded(flex: 10, child: _netImage(images[1], height: 150, radius: 12)),
      ]);
    }
    return Row(children: [
      Expanded(flex: 14, child: _netImage(images.first, height: 150, radius: 12)),
      const SizedBox(width: 6),
      Expanded(
        flex: 10,
        child: Column(
          children: [
            _netImage(images[1], height: 72, radius: 12),
            const SizedBox(height: 6),
            _netImage(images[2], height: 72, radius: 12),
          ],
        ),
      ),
    ]);
  }

  Widget _feedAction(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ]),
    );
  }
}

Widget _netImage(String url, {double? height, double? width, double radius = 10}) {
  return Container(
    height: height ?? 120,
    width: width ?? double.infinity,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
    ),
    clipBehavior: Clip.antiAlias,
    alignment: Alignment.center,
    child: Image.network(MediaUtils.resolveUrl(url),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(LucideIcons.image, size: 26, color: AppColors.textTertiary)),
  );
}

/// Circular avatar with network image + initial fallback.
class _Avatar extends StatelessWidget {
  final String? url;
  final String initial;
  final double size;
  const _Avatar({required this.initial, this.size = 45, this.url});

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE9A8), AppColors.yellow, Color(0xFFF5B400)]),
      ),
      alignment: Alignment.center,
      child: Text(initial,
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: size * 0.4, color: AppColors.ink)),
    );
    if (url != null && url!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Image.network(MediaUtils.resolveUrl(url!),
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, _, _) => inner),
      );
    }
    return inner;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rail cards (Explore / Recommended) — .rail .acard
// ─────────────────────────────────────────────────────────────────────────────

class RailPersonCard extends StatelessWidget {
  final String name;
  final String role;
  final String? photoUrl;
  final String ctaLabel;
  final VoidCallback? onTap;
  const RailPersonCard(
      {super.key, required this.name, required this.role, this.photoUrl, this.ctaLabel = 'View', this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: SportXShadows.e1,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              _netImage(photoUrl ?? '', height: 96, radius: 0),
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(LucideIcons.ellipsisVertical, size: 15, color: AppColors.textSecondary),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ),
                const _VerifiedDot(),
              ]),
              const SizedBox(height: 3),
              Text('Sport · $role',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFD54A), AppColors.yellow, Color(0xFFF5B400)]),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: const Color(0x2E785000)),
                    ),
                    alignment: Alignment.center,
                    child: Text(ctaLabel,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class RailAcademyCard extends StatelessWidget {
  final String name;
  final String location;
  final String? photoUrl;
  final VoidCallback? onTap;
  const RailAcademyCard({super.key, required this.name, required this.location, this.photoUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: SportXShadows.e1,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              _netImage(photoUrl ?? '', height: 96, radius: 0),
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(LucideIcons.ellipsisVertical, size: 15, color: AppColors.textSecondary),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 3),
              Text(location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFD54A), AppColors.yellow, Color(0xFFF5B400)]),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: const Color(0x2E785000)),
                    ),
                    alignment: Alignment.center,
                    child: Text('View', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Rail event card with the yellow date badge (.evdate) and a type chip.
class RailEventCard extends StatelessWidget {
  final String title;
  final String location;
  final DateTime? date;
  final String typeLabel;
  final String? photoUrl;
  final VoidCallback? onTap;
  const RailEventCard({
    super.key,
    required this.title,
    required this.location,
    required this.typeLabel,
    this.date,
    this.photoUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
          boxShadow: SportXShadows.e1,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              _netImage(photoUrl ?? '', height: 96, radius: 0),
              if (date != null)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(10)),
                    child: Column(children: [
                      Text('${date!.day}',
                          style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.0)),
                      Text(months[date!.month - 1],
                          style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ]),
                  ),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(LucideIcons.mapPin, size: 10, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(location,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
                  ),
                ]),
                const SizedBox(height: 6),
                TypeChip(label: typeLabel),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

/// .typechip — green for trials/tournaments/events, amber for scholarships.
class TypeChip extends StatelessWidget {
  final String label;
  const TypeChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final amber = label.toLowerCase().contains('scholarship') || label.toLowerCase().contains('sponsor');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: amber ? const Color(0xFFFFF3D6) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w800, color: amber ? AppColors.primaryDarker : const Color(0xFF15803D))),
    );
  }
}

/// Green ✓ circle shown after names (.verified).
class _VerifiedDot extends StatelessWidget {
  const _VerifiedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.verifiedBadge, shape: BoxShape.circle),
      child: const Icon(LucideIcons.check, size: 9, color: Colors.white),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Person row (Network suggestions, Our athletes…)
// ─────────────────────────────────────────────────────────────────────────────

/// .person-row — avatar 45, name + ✓, role, rating · city, trailing CTA.
class PersonRowCard extends StatelessWidget {
  final String name;
  final String role;
  final String? city;
  final String? photoUrl;
  final String ctaLabel;
  final VoidCallback? onTap;
  final VoidCallback? onCtaTap;
  final double rating;
  const PersonRowCard({
    super.key,
    required this.name,
    required this.role,
    this.city,
    this.photoUrl,
    this.ctaLabel = 'View',
    this.onTap,
    this.onCtaTap,
    this.rating = 4.8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: SportXShadows.e1,
      ),
      child: Row(children: [
        _Avatar(initial: name.isNotEmpty ? name[0].toUpperCase() : 'A', url: photoUrl, size: 45),
        const SizedBox(width: 9),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              const SizedBox(width: 4),
              const _VerifiedDot(),
            ]),
            const SizedBox(height: 3),
            Text(role,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
            const SizedBox(height: 3),
            RatingLine(rating: rating, city: city),
          ]),
        ),
        const SizedBox(width: 8),
        // CTA stays flush with the card's right edge and vertically centred
        // next to the name/role/rating block (max width guards long labels).
        Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 88),
            child: CompactPrimaryButton(label: ctaLabel, onTap: onCtaTap ?? onTap),
          ),
        ),
      ]),
    );
  }
}

/// star 4.8 · city mini-row.
class RatingLine extends StatelessWidget {
  final double rating;
  final String? city;
  const RatingLine({super.key, required this.rating, this.city});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(LucideIcons.star, size: 11, color: AppColors.yellow, fill: 1),
        const SizedBox(width: 3),
        Text(rating.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.dark)),
        if (city != null && city!.isNotEmpty) ...[
          const Text(' · ', style: TextStyle(color: AppColors.textTertiary)),
          Flexible(
            child: Text(city!,
                overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coming-soon card (filled while a provider nets nothing back)
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: SportXShadows.e1,
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, height: 1.5, color: AppColors.textSecondary)),
    );
  }
}

Widget emptyHint(String text) => _EmptyHint(text: text);

/// Public wrapper so other screens can reuse the kit's cached-image tile.
Widget kitNetImage({required String url, double? width, double? height, double radius = 10}) =>
    _netImage(url, width: width, height: height, radius: radius);

/// v3 `.tabs` — flex tab row with yellow underline on the active tab
/// (S.12 Network/Groups/Events/program lists).
class KitTabBar extends StatelessWidget {
  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onChanged;
  const KitTabBar({super.key, required this.labels, required this.activeIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      margin: const EdgeInsets.fromLTRB(2, 4, 2, 10),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(9, 10, 9, 9),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == activeIndex ? AppColors.yellow : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: i == activeIndex ? FontWeight.w800 : FontWeight.w600,
                      color: i == activeIndex ? AppColors.ink : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed preview (feedtabs + up to two posts) — homeShell() trailing module,
// shared by the athlete home and every role dashboard.
// ─────────────────────────────────────────────────────────────────────────────

class V3FeedPreview extends ConsumerStatefulWidget {
  const V3FeedPreview({super.key});

  @override
  ConsumerState<V3FeedPreview> createState() => _V3FeedPreviewState();
}

class _V3FeedPreviewState extends ConsumerState<V3FeedPreview> {
  int _tab = 0;

  void _toggleLike(SocialPost post) {
    if (post.liked) {
      unlikePost(ref, post.id);
    } else {
      togglePostLike(ref, post.id);
    }
  }

  String _authorSub(SocialPost post) {
    final t = post.createdAt?.toString() ?? '';
    if (t.isEmpty) return 'Just now';
    return 'Posted ${timeAgoShort(t)}';
  }

  Widget _post(SocialPost p) {
    final detail = '/post-detail/${p.id}';
    return PostCardV3(
      author: p.authorName,
      authorAvatar: p.authorAvatar,
      authorSub: _authorSub(p),
      body: p.body,
      images: [if ((p.imageUrl ?? '').isNotEmpty) p.imageUrl!],
      likesCount: p.likesCount,
      commentsCount: p.commentsCount,
      onLike: () => _toggleLike(p),
      onComment: () => context.push(detail),
      onTap: () => context.push(detail),
      onSave: () => context.push(detail),
    );
  }

  /// Feed filter for each tab of the feed switcher.
  static const _tabFilters = <String>[
    '',            // For You — everything the viewer may see
    'following',   // people the viewer follows
    'role:athlete',
    'role:coach',
    'role:academy',
    'role:organizer', // event announcements
  ];

  @override
  Widget build(BuildContext context) {
    final filter = _tabFilters[_tab.clamp(0, _tabFilters.length - 1)];
    final feed = ref.watch(filteredPostsFeedProvider(filter));
    final posts = feed.value ?? const <SocialPost>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeedTabsBar(
          activeIndex: _tab,
          onChanged: (i) {
            if (i == _tab) return;
            setState(() => _tab = i);
          },
        ),
        const SizedBox(height: 10),
        feed.isLoading && posts.isEmpty
            ? const PostSkeleton()
            : feed.hasError
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton.icon(
                      onPressed: () => ref.invalidate(filteredPostsFeedProvider(filter)),
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: const Text("Couldn't load feed — tap to retry"),
                    ),
                  )
                : posts.isEmpty
                    ? const SizedBox(
                        height: 90,
                        child: Center(
                          child: Text('Nothing here yet — check back soon.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ),
                      )
                    : Column(children: [
                        _post(posts.first),
                        if (posts.length > 1) ...[
                          const SizedBox(height: 12),
                          _post(posts[1]),
                        ],
                      ]),
      ],
    );
  }
}

/// Greeting line prefix for the greet card ("Good morning," etc.).
String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning,';
  if (now.hour < 17) return 'Good afternoon,';
  return 'Good evening,';
}

/// `timeAgo` helper used by feed author lines ('2h', '3d', '18/02').
String timeAgoShort(String raw) {
  final dt = DateTime.tryParse(raw);
  if (dt == null) return 'recently';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}';
}

/// Loading placeholder for the feed (matches .feed-card shape).
class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 110, height: 11, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 5),
              Container(width: 64, height: 8, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4))),
            ]),
          ]),
          const SizedBox(height: 10),
          ...List.generate(3, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          Container(
            height: 96,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
    );
  }
}
