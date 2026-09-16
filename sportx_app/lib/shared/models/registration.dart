import 'package:sportx_app/shared/models/approval.dart';

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

class TournamentRegistration {
  final int id;
  final int tournamentId;
  final int categoryId;
  final int athleteId;
  final String participationType;
  final String? teamName;
  final String paymentStatus;
  final ApprovalStatus approvalStatus;
  final String status;
  final String? rejectionReason;
  final int? reviewedBy;
  final DateTime? reviewedAt;
  final String? tournamentName;
  final String? categoryName;

  TournamentRegistration({
    required this.id,
    required this.tournamentId,
    required this.categoryId,
    required this.athleteId,
    required this.participationType,
    this.teamName,
    this.paymentStatus = 'pending',
    this.approvalStatus = ApprovalStatus.pending,
    this.status = 'pending',
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    this.tournamentName,
    this.categoryName,
  });

  bool get isPending => approvalStatus == ApprovalStatus.pending;
  bool get isApproved => approvalStatus == ApprovalStatus.approved;
  bool get isRejected => approvalStatus == ApprovalStatus.rejected;

  factory TournamentRegistration.fromJson(Map<String, dynamic> json) {
    final tournament = json['tournament'] is Map
        ? Map<String, dynamic>.from(json['tournament'] as Map)
        : null;
    final category = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : null;
    return TournamentRegistration(
      id: _parseInt(json['id'])!,
      tournamentId: _parseInt(json['tournament_id']) ?? _parseInt(tournament?['id']) ?? 0,
      categoryId: _parseInt(json['category_id']) ?? _parseInt(category?['id']) ?? 0,
      athleteId: _parseInt(json['athlete_id']) ?? 0,
      participationType: json['participation_type'] as String? ?? 'individual',
      teamName: json['team_name'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      approvalStatus: ApprovalStatusX.fromString(json['approval_status'] as String?),
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      reviewedBy: _parseInt(json['reviewed_by']),
      reviewedAt: _parseDate(json['reviewed_at']),
      tournamentName: tournament?['name'] as String? ?? tournament?['title'] as String?,
      categoryName: category?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tournament_id': tournamentId,
        'category_id': categoryId,
        'athlete_id': athleteId,
        'participation_type': participationType,
        'team_name': teamName,
        'payment_status': paymentStatus,
        'approval_status': approvalStatus.name,
        'status': status,
        'rejection_reason': rejectionReason,
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt?.toIso8601String(),
      };
}

class TrialRegistration {
  final int id;
  final int trialId;
  final int athleteId;
  final String registrationRef;
  final String documentStatus;
  final String verificationStatus;
  final ApprovalStatus approvalStatus;
  final String? rejectionReason;
  final int? reviewedBy;
  final DateTime? reviewedAt;
  final String? trialName;

  TrialRegistration({
    required this.id,
    required this.trialId,
    required this.athleteId,
    required this.registrationRef,
    this.documentStatus = 'pending',
    this.verificationStatus = 'pending',
    this.approvalStatus = ApprovalStatus.pending,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    this.trialName,
  });

  bool get isPending => approvalStatus == ApprovalStatus.pending;
  bool get isApproved => approvalStatus == ApprovalStatus.approved;
  bool get isRejected => approvalStatus == ApprovalStatus.rejected;

  factory TrialRegistration.fromJson(Map<String, dynamic> json) {
    final trial = json['trial'] is Map
        ? Map<String, dynamic>.from(json['trial'] as Map)
        : null;
    return TrialRegistration(
      id: _parseInt(json['id'])!,
      trialId: _parseInt(json['trial_id']) ?? _parseInt(trial?['id']) ?? 0,
      athleteId: _parseInt(json['athlete_id']) ?? 0,
      registrationRef: json['registration_ref'] as String? ?? '',
      documentStatus: json['document_status'] as String? ?? 'pending',
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      approvalStatus: ApprovalStatusX.fromString(json['approval_status'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
      reviewedBy: _parseInt(json['reviewed_by']),
      reviewedAt: _parseDate(json['reviewed_at']),
      trialName: trial?['name'] as String? ?? trial?['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trial_id': trialId,
        'athlete_id': athleteId,
        'registration_ref': registrationRef,
        'document_status': documentStatus,
        'verification_status': verificationStatus,
        'approval_status': approvalStatus.name,
        'rejection_reason': rejectionReason,
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt?.toIso8601String(),
      };
}
