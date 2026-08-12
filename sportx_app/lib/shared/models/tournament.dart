import 'sport.dart';
import 'city.dart';
import 'age_group.dart';

class Tournament {
  final int id;
  final String title;
  final String? description;
  final int sportId;
  final int? cityId;
  final String? venue;
  final String? googleMapsUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? registrationDeadline;
  final int? totalSpots;
  final int? filledSpots;
  final double? registrationFee;
  final double? prizePool;
  final String? ageGroupLabel;
  final int? ageGroupId;
  final String? format;
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

  Tournament({
    required this.id,
    required this.title,
    this.description,
    required this.sportId,
    this.cityId,
    this.venue,
    this.googleMapsUrl,
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.totalSpots,
    this.filledSpots,
    this.registrationFee,
    this.prizePool,
    this.ageGroupLabel,
    this.ageGroupId,
    this.format,
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

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as int,
      title: (json['title'] ?? json['name'] ?? '') as String,
      description: (json['description'] ?? json['rules']) as String?,
      sportId: json['sport_id'] as int,
      cityId: json['city_id'] as int?,
      venue: json['venue'] as String?,
      googleMapsUrl: json['google_maps_url'] as String?,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      registrationDeadline: json['registration_deadline'] != null ? DateTime.parse(json['registration_deadline']) : null,
      totalSpots: json['total_spots'] as int?,
      filledSpots: json['filled_spots'] as int?,
      // entry_fee & prize_pool are varchar on the backend → arrive as String.
      registrationFee: num.tryParse('${json['registration_fee'] ?? json['entry_fee'] ?? ''}')?.toDouble(),
      prizePool: num.tryParse('${json['prize_pool'] ?? ''}')?.toDouble(),
      ageGroupLabel: (json['age_group_label'] ?? json['gender']) as String?,
      ageGroupId: json['age_group_id'] as int?,
      format: json['format'] as String?,
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
