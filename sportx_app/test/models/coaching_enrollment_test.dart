import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/shared/models/approval.dart';
import 'package:sportx_app/shared/models/coaching_enrollment.dart';

void main() {
  group('CoachingEnrollment.fromJson', () {
    test('parses pending monthly enrollment with nested coach + athlete', () {
      final e = CoachingEnrollment.fromJson({
        'id': 1,
        'coach_id': 3,
        'athlete_id': 9,
        'plan_type': 'monthly',
        'fees_amount': '5000.00',
        'status': 'inactive',
        'approval_status': 'pending',
        'notes': 'Want to improve batting',
        'coach': {'id': 3, 'full_name': 'Coach Test'},
        'athlete': {
          'id': 9,
          'user': {'name': 'Test Athlete'}
        },
      });

      expect(e.planType, PlanType.monthly);
      expect(e.feesAmount, 5000.0);
      expect(e.isPending, isTrue);
      expect(e.isActive, isFalse);
      expect(e.coach?.fullName, 'Coach Test');
      expect((e.athlete?['user'] as Map<String, dynamic>?)?['name'], 'Test Athlete');
      expect(e.notes, 'Want to improve batting');
    });

    test('parses approved session enrollment as active', () {
      final e = CoachingEnrollment.fromJson({
        'id': 2,
        'coach_id': 3,
        'athlete_id': 9,
        'plan_type': 'session',
        'fees_amount': 500,
        'status': 'active',
        'approval_status': 'approved',
        'start_date': '2026-09-15',
        'sessions_remaining': 4,
      });

      expect(e.isApproved, isTrue);
      expect(e.isActive, isTrue);
      expect(e.startDate, isNotNull);
      expect(e.sessionsRemaining, 4);
    });

    test('parses rejected enrollment with reason', () {
      final e = CoachingEnrollment.fromJson({
        'id': 3,
        'coach_id': 3,
        'athlete_id': 10,
        'plan_type': 'quarterly',
        'fees_amount': 12000,
        'status': 'cancelled',
        'approval_status': 'rejected',
        'rejection_reason': 'Fully booked',
      });

      expect(e.isRejected, isTrue);
      expect(e.rejectionReason, 'Fully booked');
      expect(e.approvalStatus, ApprovalStatus.rejected);
    });

    test('defaults unknown plan to session', () {
      final e = CoachingEnrollment.fromJson({
        'id': 4,
        'coach_id': 1,
        'athlete_id': 1,
        'plan_type': 'weird',
      });
      expect(e.planType, PlanType.session);
    });
  });
}
