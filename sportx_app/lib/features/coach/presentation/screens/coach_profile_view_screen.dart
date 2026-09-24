import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/coach/presentation/providers/coach_provider.dart';
import 'package:sportx_app/shared/models/coach.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/social_links.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class CoachProfileViewScreen extends ConsumerWidget {
  final bool isTabContent;

  const CoachProfileViewScreen({super.key, this.isTabContent = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coachProvider);
    final profile = state.coachProfile;

    if (state.isLoading && profile == null) {
      return CoachProfileViewSkeleton(isTabContent: isTabContent);
    }

    if (profile == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.userX, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text('Profile not found', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => ref.read(coachProvider.notifier).loadCoachProfile(),
            child: const Text('Retry'),
          ),
        ]),
      );
    }

    final content = RefreshIndicator(
      onRefresh: () => ref.read(coachProvider.notifier).loadCoachProfile(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, profile),
            const SizedBox(height: 20),
            _buildSectionCard(
              title: 'About',
              child: Text(
                (profile.bio?.trim().isNotEmpty == true) ? profile.bio! : 'No bio added yet.',
                style: TextStyle(
                  fontSize: 14,
                  color: profile.bio?.trim().isNotEmpty == true ? AppColors.textPrimary : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            _buildInfoCard(context, profile),
            _buildSocialCard(context, profile),
            _buildCertificationsCard(profile),
            _buildLanguagesCard(profile),
            _buildFeeCard(profile),
            _buildAvailabilityCard(profile),
          ],
        ),
      ),
    );

    if (isTabContent) {
      return Column(
        children: [
          _buildTabAppBar(context),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('My Profile', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit2, color: AppColors.primary, size: 20),
            onPressed: () => context.push('/coach-profile-edit'),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildTabAppBar(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('My Profile', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
          FilledButton.icon(
            onPressed: () => context.push('/coach-profile-edit'),
            icon: const Icon(LucideIcons.edit2, size: 16),
            label: Text('Edit Profile', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Coach profile) {
    final photoUrl = profile.profilePhotoUrl != null ? MediaUtils.resolveUrl(profile.profilePhotoUrl!) : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: SportXShadows.e1,
      ),
      child: Row(
        children: [
          CircleAvatar(
            key: ValueKey(photoUrl ?? 'no-photo'),
            radius: 42,
            backgroundColor: AppColors.coach.withValues(alpha: 0.12),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            onBackgroundImageError: photoUrl != null ? (_, _) {} : null,
            child: photoUrl == null ? const Icon(LucideIcons.user, color: AppColors.coach, size: 36) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.fullName, style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                if (profile.headline?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(profile.headline!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(LucideIcons.briefcase, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${profile.sport?.name ?? 'Sport'} • ${profile.experience ?? 'Experience not set'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        profile.location?.trim().isNotEmpty == true
                            ? profile.location!
                            : (profile.city?.name ?? 'Location not set'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (profile.contactNumber?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.phone, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(profile.contactNumber!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Coach profile) {
    return _buildSectionCard(
      title: 'Personal Information',
      child: Column(
        children: [
          _buildInfoRow('Contact', profile.contactNumber?.trim().isNotEmpty == true ? profile.contactNumber! : 'Not set'),
          _buildInfoRow('Email', profile.email?.trim().isNotEmpty == true ? profile.email! : 'Not set'),
          _buildInfoRow('Sport', profile.sport?.name ?? 'Not set'),
          _buildInfoRow('City', profile.city != null ? '${profile.city!.name}, ${profile.city!.state}' : 'Not set'),
          _buildInfoRow('Experience', profile.experience ?? 'Not set'),
          _buildInfoRow('Qualification', profile.specialization?.trim().isNotEmpty == true ? profile.specialization! : 'Not set'),
          _buildInfoRow('Personal Coaching', profile.personalCoaching ? 'Available' : 'Not available'),
        ],
      ),
    );
  }

  Widget _buildSocialCard(BuildContext context, Coach profile) {
    return _buildSectionCard(
      title: 'Social Links',
      trailing: GestureDetector(
        onTap: () => context.push('/social-links'),
        child: Text(profile.socialLinks.isEmpty ? 'Add' : 'Edit',
            style: const TextStyle(fontSize: 13, color: AppColors.primary)),
      ),
      child: profile.socialLinks.isEmpty
          ? Text('No social links yet.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))
          : SocialLinksRow(links: profile.socialLinks),
    );
  }

  Widget _buildCertificationsCard(Coach profile) {    final certs = profile.certifications ?? [];
    final achievements = profile.achievements;
    return _buildSectionCard(
      title: 'Certifications & Achievements',
      child: (certs.isEmpty && (achievements == null || achievements.trim().isEmpty))
          ? Text('No certifications added yet.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (certs.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: certs
                        .map((c) => Chip(
                              label: Text(c, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                              avatar: const Icon(LucideIcons.award, size: 14, color: AppColors.primary),
                            ))
                        .toList(),
                  ),
                if (certs.isNotEmpty && achievements?.trim().isNotEmpty == true) const SizedBox(height: 12),
                if (achievements?.trim().isNotEmpty == true)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.trophy, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(achievements!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildLanguagesCard(Coach profile) {
    final langs = profile.languages ?? [];
    if (langs.isEmpty) return const SizedBox.shrink();
    return _buildSectionCard(
      title: 'Languages',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: langs
            .map((l) => Chip(
                  label: Text(l, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.border),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildFeeCard(Coach profile) {
    final hasAny = profile.feePerSession != null || profile.feeMonthly != null || profile.feeQuarterly != null;
    return _buildSectionCard(
      title: 'Fee Structure',
      child: !hasAny
          ? Text('No fee structure set.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))
          : Column(
              children: [
                _buildFeeRow('Per Session (90 min)', profile.feePerSession),
                const Divider(color: AppColors.border, height: 24),
                _buildFeeRow('Monthly (8 sessions)', profile.feeMonthly),
                const Divider(color: AppColors.border, height: 24),
                _buildFeeRow('Quarterly (24 sessions)', profile.feeQuarterly),
              ],
            ),
    );
  }

  Widget _buildAvailabilityCard(Coach profile) {
    final availability = profile.availability ?? {};
    final hasAvailability = availability.values.any((slots) => slots.isNotEmpty);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return _buildSectionCard(
      title: 'Weekly Availability',
      child: !hasAvailability
          ? Text('No availability set.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))
          : Column(
              children: days.where((d) => (availability[d]?.isNotEmpty ?? false)).map((day) {
                final slots = availability[day]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 40, child: Text(day, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: slots
                              .map((s) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child, Widget? trailing}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isNotSet = value == 'Not set';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isNotSet ? AppColors.textSecondary : AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, double? value) {
    return Row(
      children: [
        Row(children: [
          const Icon(LucideIcons.circleDot, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ]),
        const Spacer(),
        Text(value != null ? '₹${value.toStringAsFixed(0)}' : '—', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: value != null ? AppColors.primary : AppColors.textSecondary)),
      ],
    );
  }
}
