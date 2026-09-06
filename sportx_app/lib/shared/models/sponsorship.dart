import 'package:sportx_app/shared/models/sport.dart';
import 'package:sportx_app/shared/models/city.dart';

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
    final logo = json['logo'] as Map<String, dynamic>?;
    final sponsor = json['sponsor'] as Map<String, dynamic>?;

    return Sponsorship(
      id: _parseInt(json['id'])!,
      title: json['title'] as String,
      description: json['description'] as String?,
      sportId: _parseInt(json['sport_id'])!,
      cityId: _parseInt(json['city_id']),
      sponsorName: json['organization_name'] as String? ?? sponsor?['organization_name'] as String?,
      sponsorLogoUrl: logo?['url'] as String?,
      sponsorshipType: json['sponsorship_type'] as String?,
      amountLabel: json['amount'] != null ? '₹${_formatAmount(json['amount'])}' : null,
      minAmount: (json['min_amount'] as num?)?.toDouble(),
      maxAmount: (json['max_amount'] as num?)?.toDouble(),
      applicationDeadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      eligibility: json['eligibility_criteria'] as String?,
      benefits: json['benefits_offered'] as String?,
      applicationLink: json['application_link'] as String?,
      status: json['status'] as String? ?? 'draft',
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      sport: json['sport'] != null ? Sport.fromJson(json['sport']) : null,
      city: json['city'] != null ? City.fromJson(json['city']) : null,
      isSaved: json['is_saved'] == true || json['is_saved'] == 1,
    );
  }

  static String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num amountVal = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    if (amountVal >= 10000000) {
      return '${(amountVal / 10000000).toStringAsFixed(1)}Cr';
    } else if (amountVal >= 100000) {
      return '${(amountVal / 100000).toStringAsFixed(1)}L';
    } else if (amountVal >= 1000) {
      return '${(amountVal / 1000).toStringAsFixed(0)}K';
    }
    return amountVal.toStringAsFixed(0);
  }
}
