import 'sport.dart';
import 'city.dart';
import 'age_group.dart';

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class TournamentCategory {
  final int id;
  final String name;
  final int? ageGroupId;
  final String? ageGroupName;
  final int? capacity;

  TournamentCategory({
    required this.id,
    required this.name,
    this.ageGroupId,
    this.ageGroupName,
    this.capacity,
  });

  factory TournamentCategory.fromJson(Map<String, dynamic> json) {
    return TournamentCategory(
      id: _parseInt(json['id'])!,
      name: (json['name'] ?? '') as String,
      ageGroupId: _parseInt(json['age_group_id']),
      ageGroupName: json['age_group'] is Map ? json['age_group']['name'] as String? : null,
      capacity: (json['capacity'] is num) ? (json['capacity'] as num).toInt() : null,
    );
  }

  String get displayName => name.isNotEmpty
      ? name
      : (ageGroupName ?? 'Category $id');
}

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
  final List<TournamentCategory> categories;

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
    this.categories = const [],
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: _parseInt(json['id'])!,
      title: (json['title'] ?? json['name'] ?? '') as String,
      description: (json['description'] ?? json['rules']) as String?,
      sportId: _parseInt(json['sport_id'])!,
      cityId: _parseInt(json['city_id']),
      venue: json['venue'] as String?,
      googleMapsUrl: json['google_maps_url'] as String?,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      registrationDeadline: json['registration_deadline'] != null ? DateTime.parse(json['registration_deadline']) : null,
      totalSpots: _parseInt(json['total_spots']),
      filledSpots: _parseInt(json['filled_spots']),
      // entry_fee & prize_pool are varchar on the backend → arrive as String.
      registrationFee: num.tryParse('${json['registration_fee'] ?? json['entry_fee'] ?? ''}')?.toDouble(),
      prizePool: num.tryParse('${json['prize_pool'] ?? ''}')?.toDouble(),
      ageGroupLabel: (json['age_group_label'] ?? json['gender']) as String?,
      ageGroupId: _parseInt(json['age_group_id']),
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
      categories: (json['categories'] as List? ?? const [])
          .whereType<Map>()
          .map((c) => TournamentCategory.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }

  int? get spotsLeft => totalSpots != null ? totalSpots! - (filledSpots ?? 0) : null;
}
