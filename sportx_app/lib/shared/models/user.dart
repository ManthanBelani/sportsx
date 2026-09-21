import 'package:sportx_app/core/utils/media_utils.dart';

// ignore: constant_identifier_names
enum UserRole { athlete, coach, academy, organizer, sponsor, admin, talent_scout }

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? profilePhotoUrl;
  final bool isVerified;
  final Map<String, String> socialLinks;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.profilePhotoUrl,
    this.isVerified = false,
    this.socialLinks = const {},
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawLinks = json['social_links'];
    final links = <String, String>{};
    if (rawLinks is Map) {
      rawLinks.forEach((k, v) {
        final s = v?.toString().trim() ?? '';
        if (s.isNotEmpty) links[k.toString()] = s;
      });
    }
    return User(
      id: _parseInt(json['id'])!,
      name: json['name'] as String? ?? '',
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'athlete',
      profilePhotoUrl: MediaUtils.resolveNullable(json['profile_photo_url'] as String?),
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      socialLinks: links,
    );
  }

  UserRole get userRole {
    switch (role) {
      case 'coach': return UserRole.coach;
      case 'academy': return UserRole.academy;
      case 'organizer': return UserRole.organizer;
      case 'sponsor': return UserRole.sponsor;
      case 'admin': return UserRole.admin;
      case 'talent_scout': return UserRole.talent_scout;
      default: return UserRole.athlete;
    }
  }
}
