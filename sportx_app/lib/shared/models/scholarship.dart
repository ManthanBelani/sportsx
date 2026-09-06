import 'package:sportx_app/shared/models/sport.dart';
import 'package:sportx_app/shared/models/city.dart';

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
  final int? sportId;
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
    this.sportId,
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
    final logo = json['logo'] as Map<String, dynamic>?;
    return Scholarship(
      id: _parseInt(json['id'])!,
      title: (json['name'] ?? json['title'] ?? '') as String,
      description: json['description'] as String?,
      sportId: _parseInt(json['sport_id']),
      cityId: _parseInt(json['city_id']),
      sponsorName: (json['organization_name'] ?? json['sponsor_name']) as String?,
      sponsorLogoUrl: (logo?['url'] as String?) ?? json['sponsor_logo_url'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      amountLabel: json['amount'] != null ? '₹${_formatAmount(json['amount'])}' : null,
      totalSlots: _parseInt(json['total_slots']),
      filledSlots: _parseInt(json['filled_slots']),
      applicationDeadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
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
