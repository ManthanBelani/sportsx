import 'sport.dart';
import 'city.dart';

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

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
  final String? contactEmail;
  final String? contactPhone;
  final List<String> documentsRequired;
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
    this.contactEmail,
    this.contactPhone,
    this.documentsRequired = const [],
    required this.status,
    this.expiresAt,
    this.sport,
    this.city,
    this.isSaved = false,
  });

  factory Scholarship.fromJson(Map<String, dynamic> json) {
    return Scholarship(
      id: _parseInt(json['id'])!,
      title: (json['title'] ?? json['name'] ?? '') as String,
      description: json['description'] as String?,
      sportId: _parseInt(json['sport_id'])!,
      cityId: _parseInt(json['city_id']),
      sponsorName: (json['sponsor_name'] ?? json['organization_name']) as String?,
      sponsorLogoUrl: (json['sponsor_logo_url'] ?? json['logo_url']) as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      amountLabel: json['amount_label'] as String?,
      totalSlots: _parseInt(json['total_slots']),
      filledSlots: _parseInt(json['filled_slots']),
      applicationDeadline: (json['application_deadline'] ?? json['deadline']) != null
          ? DateTime.parse(json['application_deadline'] ?? json['deadline'])
          : null,
      eligibility: json['eligibility'] as String?,
      benefits: json['benefits'] as String?,
      applicationLink: json['application_link'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      documentsRequired: (json['documents_required'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      status: json['status'] as String? ?? 'draft',
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      sport: json['sport'] != null ? Sport.fromJson(json['sport']) : null,
      city: json['city'] != null ? City.fromJson(json['city']) : null,
      isSaved: json['is_saved'] == true || json['is_saved'] == 1,
    );
  }
}
