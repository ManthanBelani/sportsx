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

  /// Builds the mandatory-field value map from the raw `/me/profile` payload.
  ///
  /// The API returns a role-specific JSON object (athlete / coach / academy /
  /// organizer / sponsor / scout profiles all differ), so every field is read
  /// by its backend key. Values are normalised to a non-empty `String` or
  /// `null` so that empty collections (e.g. `sports: []`) count as missing.
  Map<MandatoryField, dynamic> _extractFieldValues(Map<String, dynamic>? profile) {
    final values = <MandatoryField, dynamic>{};
    if (profile == null) return values;

    final photo = _asMap(profile['photo']);
    final cover = _asMap(profile['cover']);
    final logo = _asMap(profile['logo']);
    final city = _asMap(profile['city']);
    final sport = _asMap(profile['sport']);
    final socialLinks = _asMap(profile['social_links']);

    // Identity
    values[MandatoryField.fullName] = _firstString(profile, ['full_name', 'name']);
    values[MandatoryField.dateOfBirth] = _firstString(profile, ['date_of_birth']);
    values[MandatoryField.gender] = _firstString(profile, ['gender']);
    values[MandatoryField.phone] = _firstString(profile, ['phone', 'contact_number']);

    // Media
    values[MandatoryField.profilePhoto] =
        _firstString(photo, ['url']) ??
        _firstString(logo, ['url']) ??
        _firstIdAsString(profile, ['photo_media_id', 'logo_media_id']);
    values[MandatoryField.coverPhoto] =
        _firstString(cover, ['url']) ??
        _firstIdAsString(profile, ['cover_media_id']);

    // Sports profile
    final hasSports = (profile['sports'] is List && (profile['sports'] as List).isNotEmpty) ||
        sport != null ||
        _firstId(profile, ['sport_id']) != null;
    values[MandatoryField.sports] = hasSports ? 'yes' : null;
    values[MandatoryField.skillLevel] = _firstString(profile, ['skill_level']);

    // Location
    values[MandatoryField.city] =
        _firstString(city, ['name']) ??
        _firstString(profile, ['location', 'address']) ??
        _firstIdAsString(profile, ['city_id']);

    // Bio & links
    values[MandatoryField.bio] = _firstString(profile, ['bio', 'experience', 'description']);
    values[MandatoryField.socialLinks] =
        (socialLinks != null && socialLinks.isNotEmpty) ? 'yes' : null;

    // Verification
    values[MandatoryField.verificationDoc] =
        _firstIdAsString(profile, ['verification_doc_media_id']) ??
        (_firstString(profile, ['verification_status']) == 'verified' ? 'verified' : null);

    // Role specific
    values[MandatoryField.coachingLicense] =
        _firstString(profile, ['qualification', 'coaching_license']) ??
        (_firstList(profile, ['certifications'])?.isNotEmpty == true ? 'certified' : null);
    values[MandatoryField.academyLicense] =
        _firstString(profile, ['registration_number', 'academy_license']) ??
        (profile['verification_badge'] == true ? 'verified' : null);
    values[MandatoryField.organizationName] =
        _firstString(profile, ['organization_name', 'organization', 'name']);
    values[MandatoryField.scoutingLicense] =
        _firstString(profile, ['affiliation', 'scouting_license']) ??
        (_firstList(profile, ['sports_specialization'])?.isNotEmpty == true ? 'specialized' : null);
    values[MandatoryField.companyName] =
        _firstString(profile, ['brand_name', 'company_name', 'name']);
    values[MandatoryField.taxId] =
        _firstString(profile, ['tax_id', 'gst_number', 'gstin', 'registration_number']);
    values[MandatoryField.website] = _firstString(profile, ['website']);

    return values;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// First non-empty string found under [keys].
  String? _firstString(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return null;
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is Map || value is List) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  /// First non-zero numeric id found under [keys].
  int? _firstId(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return null;
    for (final key in keys) {
      final value = map[key];
      if (value is int && value != 0) return value;
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null && parsed != 0) return parsed;
      }
    }
    return null;
  }

  String? _firstIdAsString(Map<String, dynamic>? map, List<String> keys) {
    final id = _firstId(map, keys);
    return id?.toString();
  }

  List<dynamic>? _firstList(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return null;
    for (final key in keys) {
      final value = map[key];
      if (value is List) return value;
    }
    return null;
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