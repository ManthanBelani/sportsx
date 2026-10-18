import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/theme/design_tokens.dart';

/// SportX v3 shared cards — composed by every role. Pure presentation:
/// no providers, no navigation side-effects. Screens supply data + callbacks.

/// White rounded container used as the base surface for most content.
/// v2 .card — 16px radius, 1px border, e1 shadow.
class SportXCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const SportXCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        boxShadow: SportXShadows.e1,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

/// A single metric (count + label) with a tinted icon. Dashboards, profiles.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color tintBg;
  final Color tintFg;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.tintBg = AppColors.yellowTint,
    this.tintFg = AppColors.warnText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SportXCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tintBg,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: tintFg),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
          const SizedBox(height: 1),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Profile-completion progress card with CTA (AT.6 / S.1 / role homes).
class CompletionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress; // 0..1
  final String? ctaLabel;
  final VoidCallback? onCta;

  const CompletionCard({
    super.key,
    this.title = 'Complete your profile',
    this.subtitle = 'A complete profile gets more visibility',
    required this.progress,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress.clamp(0, 1) * 100).round();
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFFFCF0)],
        ),
        border: Border.all(color: const Color(0xFFF0E3B2)),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        boxShadow: SportXShadows.e1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
              ),
              Text('$pct%',
                  style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 3),
          Text(subtitle,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: const Color(0xFFEDEFF2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFF5B400)),
            ),
          ),
          if (ctaLabel != null) ...[
            const SizedBox(height: 13),
            Align(
              alignment: Alignment.centerLeft,
              child: PrimaryButton(
                label: ctaLabel!,
                small: true,
                icon: LucideIcons.arrowRight,
                onPressed: onCta,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cover + avatar + name + verified badge + optional stat row (D.1–D.5).
class ProfileHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String avatarText;
  final bool isVerified;
  final List<({String value, String label})> stats;
  final List<Widget> actions;
  final Widget? footer;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.subtitle,
    required this.avatarText,
    this.isVerified = false,
    this.stats = const [],
    this.actions = const [],
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 116,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFE9A8), Color(0xFFFFC107), Color(0xFFF5B400)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: -32,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ink,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                alignment: Alignment.center,
                child: Text(avatarText,
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sora(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.badgeCheck,
                        size: 18, color: AppColors.verifiedBadge),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary)),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 13),
                Wrap(spacing: 10, runSpacing: 10, children: actions),
              ],
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 16),
                SportXCard(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var i = 0; i < stats.length; i++) ...[
                        if (i > 0)
                          Container(
                              width: 1, height: 32, color: AppColors.borderSoft),
                        Expanded(
                          child: Column(
                            children: [
                              Text(stats[i].value,
                                  style: GoogleFonts.sora(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink)),
                              const SizedBox(height: 2),
                              Text(stats[i].label,
                                  style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (footer != null) ...[
                const SizedBox(height: 14),
                footer!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Feed post card (S.1 / AT.1 / S.27 entry point). Presentation only.
class FeedPostCard extends StatelessWidget {
  final String authorName;
  final String authorSubtitle;
  final String authorAvatarText;
  final String timeAgo;
  final String text;
  final String? mediaLabel;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onSave;
  final VoidCallback? onMore;

  const FeedPostCard({
    super.key,
    required this.authorName,
    this.authorSubtitle = '',
    required this.authorAvatarText,
    required this.timeAgo,
    required this.text,
    this.mediaLabel,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onSave,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return SportXCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFE9A8),
                        Color(0xFFFFC107),
                        Color(0xFFF5B400)
                      ]),
                ),
                alignment: Alignment.center,
                child: Text(authorAvatarText,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(authorName,
                        style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    if (authorSubtitle.isNotEmpty)
                      Text(authorSubtitle,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(timeAgo,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textTertiary)),
              if (onMore != null)
                IconButton(
                  onPressed: onMore,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(LucideIcons.ellipsisVertical,
                      size: 18, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(text,
              style: GoogleFonts.inter(
                  fontSize: 14, height: 1.5, color: AppColors.dark)),
          if (mediaLabel != null) ...[
            const SizedBox(height: 11),
            Container(
              height: 168,
              decoration: BoxDecoration(
                color: const Color(0xFF14161A),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.image,
                      color: Colors.white70, size: 30),
                  const SizedBox(height: 6),
                  Text(mediaLabel!,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _action(
                icon: LucideIcons.heart,
                color: isLiked ? AppColors.error : AppColors.textSecondary,
                label: '$likeCount',
                onTap: onLike,
              ),
              const SizedBox(width: 18),
              _action(
                icon: LucideIcons.messageCircle,
                color: AppColors.textSecondary,
                label: '$commentCount',
                onTap: onComment,
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSave,
                child: Icon(
                    LucideIcons.bookmark,
                    size: 18,
                    color: isSaved
                        ? AppColors.yellowDeep
                        : AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required Color color,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Compact opportunity row (D.9 / S.2 Opportunities strip).
class OpportunityCard extends StatelessWidget {
  final String title;
  final String provider;
  final String typeLabel;
  final List<({IconData icon, String text})> meta;
  final Color accent;
  final VoidCallback? onTap;
  final bool isSaved;
  final VoidCallback? onSave;

  const OpportunityCard({
    super.key,
    required this.title,
    required this.provider,
    required this.typeLabel,
    this.meta = const [],
    this.accent = AppColors.yellowDeep,
    this.onTap,
    this.isSaved = false,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SportXCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(typeLabel,
                    style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: accent)),
              ),
              const Spacer(),
              if (onSave != null)
                GestureDetector(
                  onTap: onSave,
                  child: Icon(
                      LucideIcons.bookmark,
                      size: 18,
                      color: isSaved
                          ? AppColors.yellowDeep
                          : AppColors.textTertiary),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(title,
              style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(provider,
              style: GoogleFonts.inter(
                  fontSize: 12.5, color: AppColors.textSecondary)),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in meta)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.borderSoft),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(m.icon, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Text(m.text,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Leaderboard strip with top-3 podium (S.1 / AT.1 / S.6 entry).
class LeaderboardStrip extends StatelessWidget {
  final String title;
  final List<({String name, String points, String avatarText})> entries;
  final VoidCallback? onViewAll;

  const LeaderboardStrip({
    super.key,
    this.title = 'Leaderboard',
    this.entries = const [],
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
            title: title,
            actionText: onViewAll != null ? 'View All' : null,
            onActionTap: onViewAll),
        if (entries.isEmpty)
          SportXCard(
            child: Text('No rankings yet',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary)),
          )
        else
          SizedBox(
            height: 122,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final e = entries[i];
                final rank = i + 1;
                final medal = rank == 1
                    ? const Color(0xFFFFC107)
                    : rank == 2
                        ? const Color(0xFFC0C6CF)
                        : const Color(0xFFD8A15B);
                return Container(
                  width: 104,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    boxShadow: SportXShadows.e1,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: medal.withValues(alpha: 0.16)),
                        alignment: Alignment.center,
                        child: Icon(LucideIcons.medal, size: 17, color: medal),
                      ),
                      const SizedBox(height: 8),
                      Text(e.avatarText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                      const SizedBox(height: 2),
                      Text(e.points,
                          style: GoogleFonts.inter(
                              fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Empty state with optional CTA. Replaces private per-screen empties.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = LucideIcons.searchX,
    required this.title,
    this.message = '',
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.surface),
              alignment: Alignment.center,
              child: Icon(icon, size: 30, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              PrimaryButton(
                  label: actionLabel!, small: true, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal pill tab strip (profile tabs, Explore categories).
class SegmentTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const SegmentTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => SportXChip(
          label: tabs[i],
          selected: i == selectedIndex,
          onTap: () => onSelect(i),
        ),
      ),
    );
  }
}
