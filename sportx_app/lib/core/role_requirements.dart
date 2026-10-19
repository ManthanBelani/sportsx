import 'package:sportx_app/core/role_config.dart';

/// Defines mandatory fields for each role's onboarding/profile completion.
/// Used to validate profile completeness and guide users through required steps.

enum MandatoryField {
  // Core identity fields
  fullName,
  dateOfBirth,
  gender,
  phone,

  // Profile media
  profilePhoto,
  coverPhoto,

  // Sports profile
  sports,
  skillLevel,
  city,

  // Bio & links
  bio,
  socialLinks,

  // Verification
  verificationDoc,

  // Role-specific fields
  coachingLicense,      // coach
  academyLicense,       // academy
  organizationName,     // organizer, academy
  scoutingLicense,      // scout
  companyName,          // sponsor
  taxId,                // organizer, academy, sponsor
  website,              // organizer, academy, sponsor
}

/// Maps each role to its mandatory fields
const Map<SportXRole, List<MandatoryField>> mandatoryFieldsByRole = {
  SportXRole.athlete: [
    MandatoryField.fullName,
    MandatoryField.dateOfBirth,
    MandatoryField.gender,
    MandatoryField.sports,
    MandatoryField.skillLevel,
    MandatoryField.city,
    MandatoryField.profilePhoto,
  ],
  SportXRole.coach: [
    MandatoryField.fullName,
    MandatoryField.dateOfBirth,
    MandatoryField.gender,
    MandatoryField.phone,
    MandatoryField.sports,
    MandatoryField.coachingLicense,
    MandatoryField.city,
    MandatoryField.profilePhoto,
    MandatoryField.bio,
  ],
  SportXRole.academy: [
    MandatoryField.organizationName,
    MandatoryField.academyLicense,
    MandatoryField.city,
    MandatoryField.sports,
    MandatoryField.coverPhoto,
    MandatoryField.profilePhoto,
    MandatoryField.bio,
  ],
  SportXRole.organizer: [
    MandatoryField.organizationName,
    MandatoryField.city,
    MandatoryField.profilePhoto,
    MandatoryField.coverPhoto,
    MandatoryField.bio,
    MandatoryField.taxId,
    MandatoryField.website,
  ],
  SportXRole.scout: [
    MandatoryField.fullName,
    MandatoryField.dateOfBirth,
    MandatoryField.gender,
    MandatoryField.phone,
    MandatoryField.scoutingLicense,
    MandatoryField.city,
    MandatoryField.profilePhoto,
    MandatoryField.bio,
  ],
  SportXRole.sponsor: [
    MandatoryField.companyName,
    MandatoryField.city,
    MandatoryField.profilePhoto,
    MandatoryField.coverPhoto,
    MandatoryField.bio,
    MandatoryField.taxId,
    MandatoryField.website,
  ],
  SportXRole.admin: [],
};

/// Human-readable labels for each mandatory field
const Map<MandatoryField, String> mandatoryFieldLabels = {
  MandatoryField.fullName: 'Full Name',
  MandatoryField.dateOfBirth: 'Date of Birth',
  MandatoryField.gender: 'Gender',
  MandatoryField.phone: 'Phone Number',
  MandatoryField.profilePhoto: 'Profile Photo',
  MandatoryField.coverPhoto: 'Cover Photo',
  MandatoryField.sports: 'Sports',
  MandatoryField.skillLevel: 'Skill Level',
  MandatoryField.city: 'City / Location',
  MandatoryField.bio: 'Bio / About',
  MandatoryField.socialLinks: 'Social Links',
  MandatoryField.verificationDoc: 'Verification Document',
  MandatoryField.coachingLicense: 'Coaching License',
  MandatoryField.academyLicense: 'Academy License',
  MandatoryField.organizationName: 'Organization Name',
  MandatoryField.scoutingLicense: 'Scouting License',
  MandatoryField.companyName: 'Company Name',
  MandatoryField.taxId: 'Tax ID / GST',
  MandatoryField.website: 'Website',
};

/// Subtitle/description for each field
const Map<MandatoryField, String> mandatoryFieldSubtitles = {
  MandatoryField.fullName: 'Your legal name as per ID',
  MandatoryField.dateOfBirth: 'For age-group eligibility',
  MandatoryField.gender: 'For appropriate categories',
  MandatoryField.phone: 'For verification & notifications',
  MandatoryField.profilePhoto: 'Clear face photo for recognition',
  MandatoryField.coverPhoto: 'Banner image for your profile',
  MandatoryField.sports: 'Select your primary sports',
  MandatoryField.skillLevel: 'Beginner / Intermediate / Advanced / Pro',
  MandatoryField.city: 'Your current city for local discovery',
  MandatoryField.bio: 'Tell others about yourself',
  MandatoryField.socialLinks: 'Instagram, Twitter, LinkedIn, etc.',
  MandatoryField.verificationDoc: 'Govt ID for verified badge',
  MandatoryField.coachingLicense: 'Certification number & expiry',
  MandatoryField.academyLicense: 'Registration number & authority',
  MandatoryField.organizationName: 'Legal entity name',
  MandatoryField.scoutingLicense: 'Scouting certification details',
  MandatoryField.companyName: 'Registered company name',
  MandatoryField.taxId: 'GSTIN / Tax registration number',
  MandatoryField.website: 'Official website URL',
};

/// Returns the list of mandatory fields for a given role
List<MandatoryField> getMandatoryFields(SportXRole role) {
  return mandatoryFieldsByRole[role] ?? [];
}

/// Checks if a field is mandatory for a role
bool isFieldMandatory(SportXRole role, MandatoryField field) {
  return mandatoryFieldsByRole[role]?.contains(field) ?? false;
}

/// Returns the progress (0.0 to 1.0) of mandatory field completion
/// based on the provided field values map
double calculateMandatoryProgress(SportXRole role, Map<MandatoryField, dynamic> fieldValues) {
  final fields = getMandatoryFields(role);
  if (fields.isEmpty) return 1.0;
  
  int completed = 0;
  for (final field in fields) {
    final value = fieldValues[field];
    if (value != null && value.toString().isNotEmpty) {
      completed++;
    }
  }
  return completed / fields.length;
}

/// Returns incomplete mandatory fields for a role
List<MandatoryField> getIncompleteMandatoryFields(
    SportXRole role, Map<MandatoryField, dynamic> fieldValues) {
  final fields = getMandatoryFields(role);
  return fields.where((field) {
    final value = fieldValues[field];
    return value == null || value.toString().isEmpty;
  }).toList();
}