import 'sport.dart';
import 'city.dart';

class Coach {
  final int id;
  final int userId;
  final String fullName;
  final String? profilePhotoUrl;
  final int sportId;
  final int? cityId;
  final String? contactNumber;
  final String? email;
  final int? experience;
  final String? specialization;
  final String? achievements;
  final String? bio;
  final double? hourlyRate;
  final String? registrationLink;
  final String status;
  final Sport? sport;
  final City? city;
  final bool isSaved;

  Coach({
    required this.id,
    required this.userId,
    required this.fullName,
    this.profilePhotoUrl,
    required this.sportId,
    this.cityId,
    this.contactNumber,
    this.email,
    this.experience,
    this.specialization,
    this.achievements,
    this.bio,
    this.hourlyRate,
    this.registrationLink,
    required this.status,
    this.sport,
    this.city,
    this.isSaved = false,
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      fullName: json['full_name'] as String,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      sportId: json['sport_id'] as int,
      cityId: json['city_id'] as int?,
      contactNumber: json['contact_number'] as String?,
      email: json['email'] as String?,
      experience: json['experience'] as int?,
      specialization: json['specialization'] as String?,
      achievements: json['achievements'] as String?,
      bio: json['bio'] as String?,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      registrationLink: json['registration_link'] as String?,
      status: json['status'] as String? ?? 'draft',
      sport: json['sport'] != null ? Sport.fromJson(json['sport']) : null,
      city: json['city'] != null ? City.fromJson(json['city']) : null,
      isSaved: json['is_saved'] == true || json['is_saved'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'full_name': fullName,
    'profile_photo_url': profilePhotoUrl, 'sport_id': sportId,
    'city_id': cityId, 'contact_number': contactNumber, 'email': email,
    'experience': experience, 'specialization': specialization,
    'achievements': achievements, 'bio': bio, 'hourly_rate': hourlyRate,
    'registration_link': registrationLink, 'status': status,
  };
}
