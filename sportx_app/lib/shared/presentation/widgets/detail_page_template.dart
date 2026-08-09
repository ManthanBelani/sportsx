import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';

class DetailPageTemplate extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(),
                _buildContent(context),
              ],
            ),
          ),
          
          // Header Actions
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
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
                  icon: LucideIcons.heart,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Bottom CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCTA(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      height: 220,
      decoration: heroImageUrl != null
          ? BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(heroImageUrl!),
                fit: BoxFit.cover,
              ),
            )
          : const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1a365d), Color(0xFF2d5a87)],
              ),
            ),
      alignment: Alignment.center,
      child: heroImageUrl == null && heroIcon != null
          ? Icon(heroIcon, size: 72, color: Colors.white.withOpacity(0.8))
          : null,
    );
  }

  Widget _buildHeaderBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ),
              ],
            ),
            if (rating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(rating!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  if (reviewsCount != null) ...[
                    const SizedBox(width: 6),
                    Text(reviewsCount!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ],
            if (tags != null && tags!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags!.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                )).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // Details Grid
            Row(
              children: [
                const Icon(LucideIcons.clipboardList, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Details', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              padding: EdgeInsets.zero,
              children: details.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(entry.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            if (extraSections != null) ...[
              ...extraSections!,
              const SizedBox(height: 24),
            ],

            // Location Section
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Location', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            if (locationMap != null) ...[
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: locationMap,
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.building, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(addressStr, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
                ),
              ],
            ),

            const SizedBox(height: 32),

            Center(
              child: GestureDetector(
                onTap: () {
                  // Report Listing
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.flag, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    const Text('Report this listing', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, max(16, MediaQuery.of(context).padding.bottom)),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPhonePressed,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.phone, size: 20, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onCtaPressed,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(ctaText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
