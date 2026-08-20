import 'sport.dart';
import 'city.dart';

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class Sponsorship {
  final int id;
  final String title;
  final String? description;
  final int sportId;
  final int? cityId;
  final String? sponsorName;
  final String? sponsorLogoUrl;
  final String? sponsorshipType;
  final String? amountLabel;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? applicationDeadline;
  final String? eligibility;
  final String? benefits;
  final String? applicationLink;
  final String status;
  final DateTime? expiresAt;
  final Sport? sport;
  final City? city;
  final bool isSaved;

  Sponsorship({
    required this.id,
    required this.title,
    this.description,
    required this.sportId,
    this.cityId,
    this.sponsorName,
    this.sponsorLogoUrl,
    this.sponsorshipType,
    this.amountLabel,
    this.minAmount,
    this.maxAmount,
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

  factory Sponsorship.fromJson(Map<String, dynamic> json) {
    return Sponsorship(
      id: _parseInt(json['id'])!,
      title: json['title'] as String,
      description: json['description'] as String?,
      sportId: _parseInt(json['sport_id'])!,
      cityId: _parseInt(json['city_id']),
      sponsorName: json['sponsor_name'] as String?,
      sponsorLogoUrl: json['sponsor_logo_url'] as String?,
      sponsorshipType: json['sponsorship_type'] as String?,
      amountLabel: json['amount_label'] as String?,
      minAmount: (json['min_amount'] as num?)?.toDouble(),
      maxAmount: (json['max_amount'] as num?)?.toDouble(),
      applicationDeadline: json['application_deadline'] != null ? DateTime.parse(json['application_deadline']) : null,
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
