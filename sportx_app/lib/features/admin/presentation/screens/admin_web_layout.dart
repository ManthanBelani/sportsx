import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class AdminWebLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const AdminWebLayout({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(title,
            style: GoogleFonts.sora(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        actions: [
          if (actions != null) ...actions!,
          IconButton(
            icon: const Icon(LucideIcons.settings, color: AppColors.ink),
            onPressed: () {},
          ),
        ],
      ),
      body: child,
    );
  }
}

class AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: SportXShadows.e1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                if (onTap != null)
                  const Icon(LucideIcons.chevronRight, color: AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.sora(
                      fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSectionLabel extends StatelessWidget {
  final String label;
  final int? count;
  final Widget? action;

  const AdminSectionLabel({
    super.key,
    required this.label,
    this.count,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.sora(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.yellowTint,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x40F59E0B)),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    color: AppColors.warnText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (action != null) action!,
      ],
    );
  }
}

class AdminTabPills extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final Function(int) onTabChanged;

  const AdminTabPills({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SportXChip(
              label: tabs[index],
              selected: isSelected,
              onTap: () => onTabChanged(index),
            ),
          );
        }),
      ),
    );
  }
}

class AdminUserCard extends StatelessWidget {
  final String name;
  final String role;
  final String? city;
  final String? avatarUrl;
  final bool isVerified;
  final bool isActive;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AdminUserCard({
    super.key,
    required this.name,
    required this.role,
    this.city,
    this.avatarUrl,
    this.isVerified = false,
    this.isActive = true,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: SportXShadows.e1,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          backgroundColor: AppColors.yellowTint,
          child: avatarUrl == null
              ? const Icon(LucideIcons.user, color: AppColors.textTertiary)
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
            if (isVerified)
              const Icon(LucideIcons.badgeCheck, color: AppColors.verifiedBadge, size: 18),
            if (!isActive)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: StatusPill(label: 'Suspended', kind: PillKind.no),
              ),
          ],
        ),
        subtitle: Text(
          '$role${city != null ? ' · $city' : ''}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: trailing ?? const Icon(LucideIcons.chevronRight, color: AppColors.textTertiary),
        onTap: onTap,
      ),
    );
  }
}

class AdminReportCard extends StatelessWidget {
  final String reporter;
  final String reason;
  final String contentType;
  final String? contentPreview;
  final String time;
  final String status;
  final VoidCallback? onReview;

  const AdminReportCard({
    super.key,
    required this.reporter,
    required this.reason,
    required this.contentType,
    this.contentPreview,
    required this.time,
    this.status = 'pending',
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForContentType(contentType),
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  contentType.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                StatusPill(
                  label: status.toUpperCase(),
                  kind: status == 'pending' ? PillKind.pending : PillKind.ok,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (contentPreview != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.borderSoft),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  contentPreview!,
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.user, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Reported by $reporter',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Reason: $reason',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (status == 'pending' && onReview != null)
                  PrimaryButton(label: 'Review', small: true, onPressed: onReview),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForContentType(String type) {
    switch (type) {
      case 'post':
        return LucideIcons.fileText;
      case 'comment':
        return LucideIcons.messageCircle;
      case 'profile':
        return LucideIcons.user;
      default:
        return LucideIcons.flag;
    }
  }
}

class AdminOpportunityCard extends StatelessWidget {
  final String title;
  final String sponsorName;
  final String? sponsorLogo;
  final String? budget;
  final String status;
  final String time;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  const AdminOpportunityCard({
    super.key,
    required this.title,
    required this.sponsorName,
    this.sponsorLogo,
    this.budget,
    this.status = 'pending',
    required this.time,
    this.onApprove,
    this.onReject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: sponsorLogo != null ? NetworkImage(sponsorLogo!) : null,
                    backgroundColor: AppColors.surface,
                    child: sponsorLogo == null
                        ? Icon(LucideIcons.building2, color: AppColors.textTertiary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sponsorName,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          time,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: status.toUpperCase(),
                    kind: status == 'approved'
                        ? PillKind.ok
                        : status == 'rejected'
                            ? PillKind.no
                            : PillKind.pending,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              if (budget != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ctaLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    budget!,
                    style: GoogleFonts.inter(
                      color: AppColors.ctaDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (status == 'pending') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: Color(0x40EF4444)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(label: 'Approve', onPressed: onApprove),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
