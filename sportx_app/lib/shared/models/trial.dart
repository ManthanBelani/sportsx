import 'sport.dart';
import 'city.dart';
import 'age_group.dart';

class Trial {
  final int id;
  final String title;
  final String? description;
  final int sportId;
  final int? cityId;
  final int? academyId;
  final String? venue;
  final String? googleMapsUrl;
  final DateTime? trialDate;
  final DateTime? registrationDeadline;
  final int? totalSpots;
  final int? filledSpots;
  final double? registrationFee;
  final String? ageGroupLabel;
  final int? ageGroupId;
  final String? contactName;
  final String? contactNumber;
  final String? documentRequired;
  final String? registrationLink;
  final String status;
  final DateTime? expiresAt;
  final Sport? sport;
  final City? city;
  final AgeGroup? ageGroup;
  final bool isSaved;

  Trial({
    required this.id,
    required this.title,
    this.description,
    required this.sportId,
    this.cityId,
    this.academyId,
    this.venue,
    this.googleMapsUrl,
    this.trialDate,
    this.registrationDeadline,
    this.totalSpots,
    this.filledSpots,
    this.registrationFee,
    this.ageGroupLabel,
    this.ageGroupId,
    this.contactName,
    this.contactNumber,
    this.documentRequired,
    this.registrationLink,
    required this.status,
    this.expiresAt,
    this.sport,
    this.city,
    this.ageGroup,
    this.isSaved = false,
  });

  factory Trial.fromJson(Map<String, dynamic> json) {
    return Trial(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      sportId: json['sport_id'] as int,
      cityId: json['city_id'] as int?,
      academyId: json['academy_id'] as int?,
      venue: json['venue'] as String?,
      googleMapsUrl: json['google_maps_url'] as String?,
      trialDate: json['trial_date'] != null ? DateTime.parse(json['trial_date']) : null,
      registrationDeadline: json['registration_deadline'] != null ? DateTime.parse(json['registration_deadline']) : null,
      totalSpots: json['total_spots'] as int?,
      filledSpots: json['filled_spots'] as int?,
      registrationFee: (json['registration_fee'] as num?)?.toDouble(),
      ageGroupLabel: json['age_group_label'] as String?,
      ageGroupId: json['age_group_id'] as int?,
      contactName: json['contact_name'] as String?,
      contactNumber: json['contact_number'] as String?,
      documentRequired: json['document_required'] as String?,
      registrationLink: json['registration_link'] as String?,
      status: json['status'] as String? ?? 'draft',
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      sport: json['sport'] != null ? Sport.fromJson(json['sport']) : null,
      city: json['city'] != null ? City.fromJson(json['city']) : null,
      ageGroup: json['age_group'] != null ? AgeGroup.fromJson(json['age_group']) : null,
      isSaved: json['is_saved'] == true || json['is_saved'] == 1,
    );
  }

  int? get spotsLeft => totalSpots != null ? totalSpots! - (filledSpots ?? 0) : null;
}
