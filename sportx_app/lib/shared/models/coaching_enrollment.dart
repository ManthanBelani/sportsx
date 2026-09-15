import 'package:sportx_app/shared/models/approval.dart';
import 'package:sportx_app/shared/models/coach.dart';

class CoachingEnrollment {
  final int id;
  final int coachId;
  final int athleteId;
  final PlanType planType;
  final double feesAmount;
  final String approvalStatus;
  final String status;
  final String? rejectionReason;
  final String? coachResponse;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? sessionsRemaining;
  final DateTime? reviewedAt;
  final String? notes;
  final Coach? coach;
  final Map<String, dynamic>? athlete;

  CoachingEnrollment({
    required this.id,
    required this.coachId,
    required this.athleteId,
    required this.planType,
    required this.feesAmount,
    required this.approvalStatus,
    required this.status,
    this.rejectionReason,
    this.coachResponse,
    this.startDate,
    this.endDate,
    this.sessionsRemaining,
    this.reviewedAt,
    this.notes,
    this.coach,
    this.athlete,
  });

  bool get isPending => approvalStatus == 'pending';
  bool get isApproved => approvalStatus == 'approved';
  bool get isRejected => approvalStatus == 'rejected';
  bool get isActive => status == 'active';

  factory CoachingEnrollment.fromJson(Map<String, dynamic> json) {
    return CoachingEnrollment(
      id: (json['id'] as num).toInt(),
      coachId: (json['coach_id'] as num).toInt(),
      athleteId: (json['athlete_id'] as num).toInt(),
      planType: PlanTypeX.fromString(json['plan_type'] as String?),
      feesAmount: double.tryParse('${json['fees_amount']}') ?? 0,
      approvalStatus: (json['approval_status'] as String?) ?? 'pending',
      status: (json['status'] as String?) ?? 'inactive',
      rejectionReason: json['rejection_reason'] as String?,
      coachResponse: json['coach_response'] as String?,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'].toString()) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'].toString()) : null,
      sessionsRemaining: json['sessions_remaining'] as int?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'].toString()) : null,
      notes: json['notes'] as String?,
      coach: json['coach'] != null ? Coach.fromJson(Map<String, dynamic>.from(json['coach'] as Map)) : null,
      athlete: json['athlete'] != null ? Map<String, dynamic>.from(json['athlete'] as Map) : null,
    );
  }
}
