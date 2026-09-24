import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/theme/design_tokens.dart';

/// SportX v2 UI kit — pixel-mapped from sportsx-design-v2 stylesheet.
/// Pure presentation. No providers, no navigation side-effects.
class SportXShadows {
  static const e1 = [
    BoxShadow(color: Color(0x0D101415), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A101415), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const e2 = [
    BoxShadow(color: Color(0x24101415), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0D101415), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const btnShadow = [
    BoxShadow(color: Color(0x8CFFC107), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const fabShadow = [
    BoxShadow(color: Color(0x8CFFC107), blurRadius: 22, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x2E111111), blurRadius: 8, offset: Offset(0, 3)),
  ];
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool small;
  const PrimaryButton({super.key, required this.label, this.onPressed, this.icon, this.small = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: small ? 36 : DesignTokens.btnHeight,
        padding: EdgeInsets.symmetric(horizontal: small ? 14 : 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD54A), Color(0xFFFFC107), Color(0xFFF5B400)],
          ),
          borderRadius: BorderRadius.circular(small ? 11 : DesignTokens.btnRadius),
          border: Border.all(color: const Color(0x2E785000)),
          boxShadow: SportXShadows.btnShadow,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: AppColors.ink),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: small ? 13 : 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const SecondaryButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.btnRadius),
          border: Border.all(color: AppColors.border),
          boxShadow: SportXShadows.e1,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: AppColors.dark),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark)),
          ],
        ),
      ),
    );
  }
}

/// v2 top bar — white/translucent, Sora title, 1px border divider.
class SportXTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  const SportXTopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack = false,
    this.onBack,
    this.actions,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.88),
      surfaceTintColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: titleWidget ??
          (title != null
              ? Text(title!,
                  style: GoogleFonts.sora(
                      fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary))
              : null),
      centerTitle: false,
      actions: actions,
      bottom: bottom ??
          PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.border)),
    );
  }
}

/// v2 .sect-h + .seeall
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  const SectionHeader({super.key, required this.title, this.actionText, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(actionText!,
                        style: GoogleFonts.inter(
                            fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(width: 2),
                    const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// v2 .chip / .chip.on
class SportXChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  const SportXChip({super.key, required this.label, this.selected = false, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: DesignTokens.chipHeight,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFD54A), Color(0xFFFFC107)])
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
              color: selected ? const Color(0x33785000) : AppColors.border),
          boxShadow: selected ? SportXShadows.btnShadow : SportXShadows.e1,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.ink),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.ink : AppColors.dark)),
          ],
        ),
      ),
    );
  }
}

enum PillKind { pending, ok, no, draft, feat, info }

/// v2 .pill-*
class StatusPill extends StatelessWidget {
  final String label;
  final PillKind kind;
  const StatusPill({super.key, required this.label, this.kind = PillKind.pending});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    switch (kind) {
      case PillKind.ok:
        bg = AppColors.successLight;
        fg = const Color(0xFF15803D);
        border = const Color(0x4022C55E);
        break;
      case PillKind.no:
        bg = AppColors.errorLight;
        fg = const Color(0xFFB91C1C);
        border = const Color(0x40EF4444);
        break;
      case PillKind.draft:
        bg = const Color(0xFFF1F3F5);
        fg = AppColors.textSecondary;
        border = AppColors.border;
        break;
      case PillKind.feat:
        bg = const Color(0xFF16A34A);
        fg = Colors.white;
        border = Colors.transparent;
        break;
      case PillKind.info:
        bg = AppColors.infoLight;
        fg = AppColors.info;
        border = const Color(0x403B82F6);
        break;
      case PillKind.pending:
        bg = AppColors.yellowTint;
        fg = AppColors.warnText;
        border = const Color(0x40F59E0B);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

/// v2 .entity + .avatar
class EntityRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String avatarText;
  final VoidCallback? onTap;
  final Widget? trailing;
  const EntityRow(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.avatarText,
      this.onTap,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          boxShadow: SportXShadows.e1,
        ),
        child: Row(
          children: [
            Container(
              width: DesignTokens.avatarSm,
              height: DesignTokens.avatarSm,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFE9A8), Color(0xFFFFC107), Color(0xFFF5B400)],
                ),
              ),
              alignment: Alignment.center,
              child: Text(avatarText,
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            trailing ??
                const Icon(LucideIcons.chevronRight, color: Color(0xFFC9CDD3), size: 20),
          ],
        ),
      ),
    );
  }
}

/// v2 .opp card
class OppCard extends StatelessWidget {
  final String title;
  final String org;
  final List<({IconData icon, String text})> meta;
  final bool featured;
  final VoidCallback? onTap;
  const OppCard(
      {super.key,
      required this.title,
      required this.org,
      this.meta = const [],
      this.featured = false,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
          boxShadow: SportXShadows.e1,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: DesignTokens.oppThumbHeight,
                  color: const Color(0xFF14161A),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.trophy, color: Colors.white70, size: 46),
                ),
                if (featured)
                  const Positioned(
                    top: 10,
                    left: 10,
                    child: StatusPill(label: 'FEATURED', kind: PillKind.feat),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.sora(
                          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(org,
                      style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary)),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final m in meta)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
                                        fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// v2 .greet + .pbar
class GreetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress; // 0..1
  final String avatarText;
  const GreetCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.progress,
      required this.avatarText});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFFFFCF0)]),
        border: Border.all(color: const Color(0xFFF0E3B2)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: SportXShadows.e1,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: DesignTokens.avatarMd,
                height: DesignTokens.avatarMd,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFE9A8), Color(0xFFFFC107), Color(0xFFF5B400)]),
                ),
                alignment: Alignment.center,
                child: Text(avatarText,
                    style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text('$pct%',
                  style: GoogleFonts.sora(
                      fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFEDEFF2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFF5B400)),
            ),
          ),
        ],
      ),
    );
  }
}

/// v2 .tiles > .tile
class QuickTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color tintBg;
  final Color tintFg;
  final VoidCallback? onTap;
  const QuickTile(
      {super.key,
      required this.label,
      required this.icon,
      required this.tintBg,
      required this.tintFg,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          boxShadow: SportXShadows.e1,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: tintBg),
              alignment: Alignment.center,
              child: Icon(icon, size: 19, color: tintFg),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.sora(
                      fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

/// v2 .searchbar
class SportXSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  const SportXSearchBar({super.key, required this.hint, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: DesignTokens.inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: SportXShadows.e1,
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.search, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(hint,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

/// v2 .iconbtn
class SportXIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final int? badge;
  const SportXIconButton({super.key, required this.icon, this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: DesignTokens.iconBtnSize,
            height: DesignTokens.iconBtnSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              boxShadow: SportXShadows.e1,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: AppColors.dark),
          ),
          if (badge != null)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text('$badge',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
