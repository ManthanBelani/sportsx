import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/shared/models/sport.dart';

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

/// Unified opportunity (Phase 4): scholarship / sponsorship / tryout / camp
/// posted by an academy, organizer, coach or scout.
class Opportunity {
  final int id;
  final String type;
  final String title;
  final String? description;
  final String? eligibility;
  final String? benefits;
  final double? amount;
  final DateTime? deadline;
  final String status;
  final Sport? sport;
  final String? ageGroup;
  final String? logoUrl;
  final bool applied;
  final String? applicationStatus;
  final bool saved;

  Opportunity({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.eligibility,
    this.benefits,
    this.amount,
    this.deadline,
    required this.status,
    this.sport,
    this.ageGroup,
    this.logoUrl,
    this.applied = false,
    this.applicationStatus,
    this.saved = false,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    final logo = json['logo'] as Map<String, dynamic>?;
    final ageGroup = json['age_group'] as Map<String, dynamic>?;
    return Opportunity(
      id: _parseInt(json['id'])!,
      type: json['type'] as String? ?? 'scholarship',
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      eligibility: json['eligibility'] as String?,
      benefits: json['benefits'] as String?,
      amount: _parseDouble(json['amount']),
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
      status: json['status'] as String? ?? 'draft',
      sport: json['sport'] is Map ? Sport.fromJson(json['sport'] as Map<String, dynamic>) : null,
      ageGroup: ageGroup?['name'] as String?,
      logoUrl: MediaUtils.resolveNullable(logo?['url'] as String?),
      applied: json['applied'] == true,
      applicationStatus: json['application_status'] as String?,
      saved: json['saved'] == true,
    );
  }

  String get amountLabel {
    if (amount == null) return '';
    if (amount! >= 10000000) return '₹${(amount! / 10000000).toStringAsFixed(1)}Cr';
    if (amount! >= 100000) return '₹${(amount! / 100000).toStringAsFixed(1)}L';
    if (amount! >= 1000) return '₹${(amount! / 1000).toStringAsFixed(0)}K';
    return '₹${amount!.toStringAsFixed(0)}';
  }
}

class OpportunityApplication {
  final int id;
  final int opportunityId;
  final int athleteId;
  final String pitch;
  final String status;
  final String? decisionNote;
  final String? athleteName;
  final Map<String, dynamic>? snapshot;

  OpportunityApplication({
    required this.id,
    required this.opportunityId,
    required this.athleteId,
    required this.pitch,
    required this.status,
    this.decisionNote,
    this.athleteName,
    this.snapshot,
  });

  factory OpportunityApplication.fromJson(Map<String, dynamic> json) {
    final athlete = json['athlete'] as Map<String, dynamic>?;
    return OpportunityApplication(
      id: _parseInt(json['id'])!,
      opportunityId: _parseInt(json['opportunity_id']) ?? 0,
      athleteId: _parseInt(json['athlete_id']) ?? 0,
      pitch: json['pitch'] as String? ?? '',
      status: json['status'] as String? ?? 'submitted',
      decisionNote: json['decision_note'] as String?,
      athleteName: athlete?['full_name'] as String? ?? (athlete?['user'] is Map ? (athlete!['user'] as Map)['name'] as String? : null),
      snapshot: json['snapshot'] is Map ? Map<String, dynamic>.from(json['snapshot'] as Map) : null,
    );
  }
}
