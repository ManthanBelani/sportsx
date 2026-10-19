import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/role_config.dart';
import 'package:sportx_app/core/role_requirements.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/providers/profile_provider.dart';

/// AT.6 Profile Completion Checklist — dynamically driven by role requirements.
class ProfileCompletionScreen extends ConsumerWidget {
  const ProfileCompletionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final role = authState.user?.role != null
        ? sportXRoleFromId(authState.user!.role)
        : SportXRole.athlete;
    final mandatoryFields = getMandatoryFields(role ?? SportXRole.athlete);

    // Watch profile data to determine completion
    final profileAsync = ref.watch(profileProvider);
    
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Profile Completion', showBack: true),
      body: profileAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
        error: (_, _) => _buildErrorState(context),
        data: (profile) {
          final fieldValues = _extractFieldValues(profile);
          final progress = calculateMandatoryProgress(role ?? SportXRole.athlete, fieldValues);
          final incompleteFields = getIncompleteMandatoryFields(role ?? SportXRole.athlete, fieldValues);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              CompletionCard(
                title: 'You\'re ${(progress * 100).round()}% complete',
                subtitle: 'Finish the remaining steps to get discovered faster',
                progress: progress,
              ),
              const SizedBox(height: 18),
              Text(
                mandatoryFields.isEmpty 
                    ? 'All mandatory fields complete!'
                    : 'Suggested next steps',
                style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink),
              ),
              const SizedBox(height: 12),
              if (mandatoryFields.isEmpty)
                _buildAllComplete(context)
              else
                for (final field in incompleteFields) _buildFieldRow(context, ref, field),
              if (incompleteFields.isEmpty && mandatoryFields.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildAllComplete(context),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.alertCircle, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('Could not load profile', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/profile-completion'),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAllComplete(BuildContext context) {
    return SportXCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.checkCircle, size: 19, color: Color(0xFF15803D)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All mandatory fields complete!',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('Your profile is ready for discovery',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const StatusPill(label: 'COMPLETE', kind: PillKind.ok),
        ],
      ),
    );
  }

  Widget _buildFieldRow(BuildContext context, WidgetRef ref, MandatoryField field) {
    final label = mandatoryFieldLabels[field] ?? field.name;
    final subtitle = mandatoryFieldSubtitles[field] ?? '';
    final icon = _iconForField(field);
    final route = _routeForField(field);

    return SportXCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => context.push(route),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  Map<MandatoryField, dynamic> _extractFieldValues(dynamic profile) {
    final values = <MandatoryField, dynamic>{};
    if (profile == null) return values;

    // Extract values from profile model
    // This depends on the actual User/AthleteProfile model structure
    values[MandatoryField.fullName] = profile.fullName ?? profile.name;
    values[MandatoryField.dateOfBirth] = profile.dateOfBirth;
    values[MandatoryField.gender] = profile.gender;
    values[MandatoryField.phone] = profile.phone;
    values[MandatoryField.profilePhoto] = profile.profilePhotoUrl;
    values[MandatoryField.coverPhoto] = profile.coverPhotoUrl;
    values[MandatoryField.sports] = profile.sports;
    values[MandatoryField.skillLevel] = profile.skillLevel;
    values[MandatoryField.city] = profile.city;
    values[MandatoryField.bio] = profile.bio;
    values[MandatoryField.socialLinks] = profile.socialLinks;
    values[MandatoryField.verificationDoc] = profile.verificationDoc;
    values[MandatoryField.coachingLicense] = profile.coachingLicense;
    values[MandatoryField.academyLicense] = profile.academyLicense;
    values[MandatoryField.organizationName] = profile.organizationName;
    values[MandatoryField.scoutingLicense] = profile.scoutingLicense;
    values[MandatoryField.companyName] = profile.companyName;
    values[MandatoryField.taxId] = profile.taxId;
    values[MandatoryField.website] = profile.website;

    return values;
  }

  IconData _iconForField(MandatoryField field) {
    switch (field) {
      case MandatoryField.fullName:
      case MandatoryField.organizationName:
      case MandatoryField.companyName:
        return LucideIcons.user;
      case MandatoryField.dateOfBirth:
        return LucideIcons.calendar;
      case MandatoryField.gender:
        return LucideIcons.users;
      case MandatoryField.phone:
        return LucideIcons.phone;
      case MandatoryField.profilePhoto:
        return LucideIcons.camera;
      case MandatoryField.coverPhoto:
        return LucideIcons.image;
      case MandatoryField.sports:
        return LucideIcons.dumbbell;
      case MandatoryField.skillLevel:
        return LucideIcons.trendingUp;
      case MandatoryField.city:
        return LucideIcons.mapPin;
      case MandatoryField.bio:
        return LucideIcons.fileText;
      case MandatoryField.socialLinks:
        return LucideIcons.link;
      case MandatoryField.verificationDoc:
        return LucideIcons.badgeCheck;
      case MandatoryField.coachingLicense:
      case MandatoryField.academyLicense:
      case MandatoryField.scoutingLicense:
        return LucideIcons.award;
      case MandatoryField.taxId:
        return LucideIcons.fileText;
      case MandatoryField.website:
        return LucideIcons.globe;
    }
  }

  String _routeForField(MandatoryField field) {
    switch (field) {
      case MandatoryField.fullName:
      case MandatoryField.dateOfBirth:
      case MandatoryField.gender:
      case MandatoryField.phone:
      case MandatoryField.bio:
      case MandatoryField.socialLinks:
        return '/edit-profile';
      case MandatoryField.profilePhoto:
      case MandatoryField.coverPhoto:
        return '/media-gallery';
      case MandatoryField.sports:
      case MandatoryField.skillLevel:
        return '/manage-sports';
      case MandatoryField.city:
        return '/edit-profile'; // or a location picker screen
      case MandatoryField.verificationDoc:
        return '/verification';
      case MandatoryField.coachingLicense:
      case MandatoryField.academyLicense:
      case MandatoryField.scoutingLicense:
      case MandatoryField.organizationName:
      case MandatoryField.companyName:
      case MandatoryField.taxId:
      case MandatoryField.website:
        return '/edit-profile'; // Role-specific profile edit screens
    }
  }
}