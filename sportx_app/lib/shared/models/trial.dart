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
      title: (json['title'] ?? json['name'] ?? '') as String,
      description: (json['description'] ?? json['benefits']) as String?,
      sportId: json['sport_id'] as int,
      cityId: json['city_id'] as int?,
      academyId: json['academy_id'] as int?,
      venue: json['venue'] as String?,
      googleMapsUrl: json['google_maps_url'] as String?,
      trialDate: (json['trial_date'] ?? json['event_datetime']) != null
          ? DateTime.parse(json['trial_date'] ?? json['event_datetime'])
          : null,
      registrationDeadline: json['registration_deadline'] != null ? DateTime.parse(json['registration_deadline']) : null,
      totalSpots: (json['total_spots'] ?? json['vacancies']) as int?,
      filledSpots: json['filled_spots'] as int?,
      // entry_fee is a varchar on the backend → arrives as a String; parse defensively.
      registrationFee: _parseNum(json['registration_fee'] ?? json['entry_fee'])?.toDouble(),
      ageGroupLabel: (json['age_group_label'] ?? json['eligibility']) as String?,
      ageGroupId: json['age_group_id'] as int?,
      contactName: json['contact_name'] as String?,
      contactNumber: json['contact_number'] as String?,
      // required_documents is a JSON column → arrives as a List, not a String.
      documentRequired: _documentsToString(json['document_required'] ?? json['required_documents']),
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

  static num? _parseNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  static String? _documentsToString(dynamic v) {
    if (v == null) return null;
    if (v is List) return v.map((e) => e.toString()).join(', ');
    return v.toString();
  }
}
