import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/saved/presentation/providers/saved_provider.dart';
import 'package:sportx_app/theme/colors.dart';

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
                _buildContent(context, ref),
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
                  // lucide icons don't react to Icon.fill — use the filled
                  // Material favorite glyph so the saved state is visible.
                  icon: isSaved ? Icons.favorite : LucideIcons.heart,
                  iconColor: isSaved ? Colors.red : AppColors.textPrimary,
                  onTap: canSave
                      ? () async {
                          final saved = await ref
                              .read(savedProvider.notifier)
                              .toggle(type: savedType!, itemId: savedItemId!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(saved ? 'Saved to your list' : 'Removed from saved')),
                            );
                          }
                        }
                      : null,
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

  Widget _buildHeaderBtn({required IconData icon, required VoidCallback? onTap, Color? iconColor}) {
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
        child: Icon(
          icon,
          color: iconColor ?? AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
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
                onTap: () => _showReportDialog(context, ref),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.flag, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 6),
                    Text('Report this listing', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportDialog(BuildContext context, WidgetRef ref) async {
    if (savedType == null || savedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This listing cannot be reported')),
      );
      return;
    }

    const reasons = {
      'fake': 'Fake / misleading',
      'outdated': 'Outdated',
      'inappropriate': 'Inappropriate',
      'other': 'Other',
    };
    String selectedReason = 'fake';
    final commentController = TextEditingController();
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text('Report this listing', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...reasons.entries.map((e) => RadioListTile<String>(
                    value: e.key,
                    groupValue: selectedReason,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(e.value, style: const TextStyle(fontSize: 14)),
                    onChanged: (v) => setDialogState(() => selectedReason = v!),
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 3,
                enabled: !submitting,
                decoration: InputDecoration(
                  hintText: 'Add details (optional)',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: submitting
                  ? null
                  : () async {
                      setDialogState(() => submitting = true);
                      try {
                        await ref.read(dioProvider).post('/reports', data: {
                          'reportable_type': savedType,
                          'reportable_id': int.parse(savedItemId!),
                          'reason': selectedReason,
                          'comment': commentController.text.trim(),
                        });
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Report submitted. Thank you!')),
                          );
                        }
                      } on DioException catch (e) {
                        setDialogState(() => submitting = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text(ApiException.fromDio(e).message)),
                          );
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context) {
    final hasSecondary = secondaryCtaText != null && onSecondaryCtaPressed != null;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, max(16, MediaQuery.of(context).padding.bottom)),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
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
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.phone, size: 20, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (hasSecondary) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: isSecondaryCtaLoading ? null : onSecondaryCtaPressed,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isSecondaryCtaLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(secondaryCtaText!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onCtaPressed,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(ctaText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ] else ...[
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
        ],
      ),
    );
  }
}
