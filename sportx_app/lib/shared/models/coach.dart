import 'dart:convert';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/shared/models/sport.dart';
import 'package:sportx_app/shared/models/city.dart';

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class Coach {
  final int id;
  final int userId;
  final String fullName;
  final String? profilePhotoUrl;
  final int sportId;
  final int? cityId;
  final String? contactNumber;
  final String? email;
  final String? experience;
  final String? specialization;
  final String? achievements;
  final String? bio;
  final double? hourlyRate;
  final double? feePerSession;
  final double? feeMonthly;
  final double? feeQuarterly;
  final String? feeStructure;
  final String? location;
  final String? headline;
  final Map<String, List<String>>? availability;
  final List<String>? certifications;
  final List<String>? languages;
  final bool personalCoaching;
  final String? registrationLink;
  final String status;
  final Sport? sport;
  final City? city;
  final bool isSaved;
  final double? rating;
  final double? avgRating;

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
    this.feePerSession,
    this.feeMonthly,
    this.feeQuarterly,
    this.feeStructure,
    this.location,
    this.headline,
    this.availability,
    this.certifications,
    this.languages,
    this.personalCoaching = false,
    this.registrationLink,
    required this.status,
    this.sport,
    this.city,
    this.isSaved = false,
    this.rating,
    this.avgRating,
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>>? parseAvailability(dynamic val) {
      if (val == null) return null;
      if (val is Map) {
        return val.map((key, value) {
          if (value is List) {
            return MapEntry(key as String, value.map((e) => e.toString()).toList());
          }
          return MapEntry(key as String, <String>[]);
        });
      }
      if (val is String) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is Map) {
            return decoded.map((key, value) {
              if (value is List) {
                return MapEntry(key as String, value.map((e) => e.toString()).toList());
              }
              return MapEntry(key as String, <String>[]);
            });
          }
        } catch (_) {}
      }
      return null;
    }

    List<String>? parseListString(dynamic val) {
      if (val == null) return null;
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
        return val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return null;
    }

    return Coach(
      id: _parseInt(json['id'])!,
      userId: _parseInt(json['user_id'])!,
      fullName: json['full_name'] as String,
      profilePhotoUrl: MediaUtils.resolveNullable(json['profile_photo_url'] as String? ?? json['photo']?['url'] as String?),
      sportId: _parseInt(json['sport_id'])!,
      cityId: _parseInt(json['city_id']),
      contactNumber: json['contact_number'] as String?,
      email: json['email'] as String?,
      experience: json['experience'] as String?,
      specialization: json['qualification'] as String? ?? json['specialization'] as String?,
      achievements: (() {
        final a = json['achievements'];
        if (a == null) return null;
        if (a is String) return a;
        if (a is List) {
          if (a.isEmpty) return null;
          // List of {text,title} or strings
          return a.map((e) {
            if (e is Map) return (e['text'] ?? e['title'] ?? '').toString();
            return e.toString();
          }).where((s) => s.trim().isNotEmpty).join(', ');
        }
        return a.toString();
      })(),
      bio: json['bio'] as String?,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      feePerSession: (json['fee_per_session'] is String)
          ? double.tryParse(json['fee_per_session'] as String)
          : (json['fee_per_session'] as num?)?.toDouble(),
      feeMonthly: (json['fee_monthly'] is String)
          ? double.tryParse(json['fee_monthly'] as String)
          : (json['fee_monthly'] as num?)?.toDouble(),
      feeQuarterly: (json['fee_quarterly'] is String)
          ? double.tryParse(json['fee_quarterly'] as String)
          : (json['fee_quarterly'] as num?)?.toDouble(),
      feeStructure: json['fee_structure'] as String?,
      location: json['location'] as String?,
      headline: json['headline'] as String?,
      availability: parseAvailability(json['availability']),
      certifications: parseListString(json['certifications']),
      languages: parseListString(json['languages']),
      personalCoaching: json['personal_coaching'] == true || json['personal_coaching'] == 1,
      registrationLink: json['registration_link'] as String?,
      status: json['status'] as String? ?? 'draft',
      sport: json['sport'] != null ? Sport.fromJson(json['sport']) : null,
      city: json['city'] != null ? City.fromJson(json['city']) : null,
      isSaved: json['is_saved'] == true || json['is_saved'] == 1,
      rating: _parseDouble(json['rating']),
      avgRating: _parseDouble(json['avg_rating'] ?? json['avgRating'] ?? json['average_rating']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'full_name': fullName,
    'profile_photo_url': profilePhotoUrl, 'sport_id': sportId,
    'city_id': cityId, 'contact_number': contactNumber, 'email': email,
    'experience': experience, 'specialization': specialization,
    'achievements': achievements, 'bio': bio, 'hourly_rate': hourlyRate,
    'fee_per_session': feePerSession, 'fee_monthly': feeMonthly, 'fee_quarterly': feeQuarterly,
    'location': location, 'headline': headline, 'availability': availability,
    'registration_link': registrationLink, 'status': status,
    'rating': rating, 'avg_rating': avgRating,
  };
}
