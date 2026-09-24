import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/saved/presentation/providers/saved_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/theme/design_tokens.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class DetailPageTemplate extends ConsumerWidget {
  final String? heroImageUrl;
  final IconData? heroIcon;
  final String title;
  final String subtitle;
  final String? rating;
  final String? reviewsCount;
  final List<String>? tags;
  final Map<String, String> details;
  final List<Widget>? extraSections;
  final Widget? locationMap;
  final String addressStr;
  final String ctaText;
  final VoidCallback onCtaPressed;
  final VoidCallback? onPhonePressed;

  /// Optional secondary CTA (e.g., "Connect" button).
  final String? secondaryCtaText;
  final VoidCallback? onSecondaryCtaPressed;
  final bool isSecondaryCtaLoading;

  /// Item type used for the save/unsave heart (e.g. 'trial', 'academy').
  final String? savedType;

  /// Remote id of the item to save/unsave.
  final String? savedItemId;

  const DetailPageTemplate({
    super.key,
    this.heroImageUrl,
    this.heroIcon,
    required this.title,
    required this.subtitle,
    this.rating,
    this.reviewsCount,
    this.tags,
    required this.details,
    this.extraSections,
    this.locationMap,
    required this.addressStr,
    required this.ctaText,
    required this.onCtaPressed,
    this.onPhonePressed,
    this.secondaryCtaText,
    this.onSecondaryCtaPressed,
    this.isSecondaryCtaLoading = false,
    this.savedType,
    this.savedItemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedState = ref.watch(savedProvider);
    final canSave = savedType != null && savedItemId != null;
    final isSaved = canSave && savedState.isSaved(savedType!, savedItemId!);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(),
                _buildContent(context),
              ],
            ),
          ),

          // Header Actions — v2 .hbtn (frosted dark circle)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeaderBtn(
                  icon: LucideIcons.arrowLeft,
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                _buildHeaderBtn(
                  // lucide icons don't react to Icon.fill — use the filled
                  // Material favorite glyph so the saved state is visible.
                  icon: isSaved ? Icons.favorite : LucideIcons.heart,
                  iconColor: isSaved ? Colors.red : Colors.white,
                  onTap: canSave
                      ? () async {
                          final saved = await ref
                              .read(savedProvider.notifier)
                              .toggle(type: savedType!, itemId: savedItemId!);
                          if (context.mounted) {
                            SnackBarUtils.showSuccess(context, saved ? 'Saved to your list' : 'Removed from saved');
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),

          // Bottom CTA — v2 .stickybar
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: _buildBottomCTA(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    // v2 .hero — dark photo block, 230px, gradient overlay via OppCard thumb.
    return Container(
      height: 230,
      decoration: heroImageUrl != null
          ? BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(heroImageUrl!),
                fit: BoxFit.cover,
              ),
            )
          : const BoxDecoration(color: Color(0xFF14161A)),
      alignment: Alignment.center,
      child: heroImageUrl == null
          ? Icon(heroIcon ?? LucideIcons.trophy,
              size: 46, color: Colors.white.withValues(alpha: 0.9))
          : null,
    );
  }

  Widget _buildHeaderBtn({required IconData icon, required VoidCallback? onTap, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0x73141416),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // v2 detail card overlapping hero: white, 20px radius, e1 shadow.
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: SportXShadows.e1,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section — v2 Sora 19
            Text(title,
                style: GoogleFonts.sora(
                    fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.25)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary)),
                ),
              ],
            ),
            if (rating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.star, size: 16, color: AppColors.yellowDeep),
                  const SizedBox(width: 4),
                  Text(rating!,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  if (reviewsCount != null) ...[
                    const SizedBox(width: 6),
                    Text(reviewsCount!,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ],
            if (tags != null && tags!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags!
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.borderSoft),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(tag,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 20),

            // Details Grid — v2 white cards on surface
            Row(
              children: [
                const Icon(LucideIcons.clipboardList, size: 18, color: AppColors.yellowDeep),
                const SizedBox(width: 8),
                Text('Details',
                    style: GoogleFonts.sora(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              padding: EdgeInsets.zero,
              children: details.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.borderSoft),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(entry.key,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(entry.value,
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            if (extraSections != null) ...[
              ...extraSections!,
              const SizedBox(height: 20),
            ],

            // Location Section
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 18, color: AppColors.yellowDeep),
                const SizedBox(width: 8),
                Text('Location',
                    style: GoogleFonts.sora(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            if (locationMap != null) ...[
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: locationMap,
              ),
              const SizedBox(height: 12),
            ],
            EntityRow(
              title: addressStr.split(',').first.trim(),
              subtitle: addressStr,
              avatarText: addressStr.isNotEmpty ? addressStr[0].toUpperCase() : 'V',
              trailing: const Icon(LucideIcons.navigation,
                  size: 18, color: AppColors.textSecondary),
            ),

            const SizedBox(height: 16),

            Center(
              child: GestureDetector(
                onTap: () {
                  if (savedType == null || savedItemId == null) {
                    SnackBarUtils.showSuccess(
                        context, 'This listing cannot be reported');
                    return;
                  }
                  context.push('/report', extra: {
                    'type': savedType,
                    'id': savedItemId,
                    'title': title,
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.flag, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Report this listing',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context) {
    final hasSecondary = secondaryCtaText != null && onSecondaryCtaPressed != null;

    // v2 .stickybar — floating rounded bar, blur white, 18px radius, e2 shadow.
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: SportXShadows.e2,
      ),
      child: Row(
        children: [
          if (onPhonePressed != null && !hasSecondary) ...[
            GestureDetector(
              onTap: onPhonePressed,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: SportXShadows.e1,
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.phone, size: 20, color: AppColors.dark),
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (hasSecondary) ...[
            Expanded(
              child: SecondaryButton(
                  label: isSecondaryCtaLoading ? 'Please wait…' : secondaryCtaText!,
                  onPressed: isSecondaryCtaLoading ? null : onSecondaryCtaPressed),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(label: ctaText, onPressed: onCtaPressed),
            ),
          ] else ...[
            Expanded(
              child: PrimaryButton(label: ctaText, onPressed: onCtaPressed),
            ),
          ],
        ],
      ),
    );
  }
}
