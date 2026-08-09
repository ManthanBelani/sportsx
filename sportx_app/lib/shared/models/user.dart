enum UserRole { athlete, coach, academy, organizer, sponsor, admin }

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? profilePhotoUrl;
  final bool isVerified;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.profilePhotoUrl,
    this.isVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'athlete',
      profilePhotoUrl: json['profile_photo_url'] as String?,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
    );
  }

  UserRole get userRole {
    switch (role) {
      case 'coach': return UserRole.coach;
      case 'academy': return UserRole.academy;
      case 'organizer': return UserRole.organizer;
      case 'sponsor': return UserRole.sponsor;
      case 'admin': return UserRole.admin;
      default: return UserRole.athlete;
    }
  }
}
