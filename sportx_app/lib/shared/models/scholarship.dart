import 'sport.dart';
import 'city.dart';

class Scholarship {
  final int id;
  final String title;
  final String? description;
  final int sportId;
  final int? cityId;
  final String? sponsorName;
  final String? sponsorLogoUrl;
  final double? amount;
  final String? amountLabel;
  final int? totalSlots;
  final int? filledSlots;
  final DateTime? applicationDeadline;
  final String? eligibility;
  final String? benefits;
  final String? applicationLink;
  final String status;
  final DateTime? expiresAt;
  final Sport? sport;
  final City? city;
  final bool isSaved;

  Scholarship({
    required this.id,
    required this.title,
    this.description,
    required this.sportId,
    this.cityId,
    this.sponsorName,
    this.sponsorLogoUrl,
    this.amount,
    this.amountLabel,
    this.totalSlots,
    this.filledSlots,
    this.applicationDeadline,
    this.eligibility,
    this.benefits,
    this.applicationLink,
    required this.status,
    this.expiresAt,
    this.sport,
    this.city,
    this.isSaved = false,
  });

  factory Scholarship.fromJson(Map<String, dynamic> json) {
    return Scholarship(
      id: json['id'] as int,
      title: (json['title'] ?? json['name'] ?? '') as String,
      description: json['description'] as String?,
      sportId: json['sport_id'] as int,
      cityId: json['city_id'] as int?,
      sponsorName: (json['sponsor_name'] ?? json['organization_name']) as String?,
      sponsorLogoUrl: (json['sponsor_logo_url'] ?? json['logo_url']) as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      amountLabel: json['amount_label'] as String?,
      totalSlots: json['total_slots'] as int?,
      filledSlots: json['filled_slots'] as int?,
      applicationDeadline: (json['application_deadline'] ?? json['deadline']) != null
          ? DateTime.parse(json['application_deadline'] ?? json['deadline'])
          : null,
      eligibility: json['eligibility'] as String?,
      benefits: json['benefits'] as String?,
      applicationLink: json['application_link'] as String?,
      status: json['status'] as String? ?? 'draft',
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      sport: json['sport'] != null ? Sport.fromJson(json['sport']) : null,
      city: json['city'] != null ? City.fromJson(json['city']) : null,
      isSaved: json['is_saved'] == true || json['is_saved'] == 1,
    );
  }
}
