import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/shared/models/approval.dart';
import 'package:sportx_app/shared/models/registration.dart';

void main() {
  group('ApprovalStatus', () {
    test('parses known values and defaults unknown to pending', () {
      expect(ApprovalStatusX.fromString('approved'), ApprovalStatus.approved);
      expect(ApprovalStatusX.fromString('rejected'), ApprovalStatus.rejected);
      expect(ApprovalStatusX.fromString('pending'), ApprovalStatus.pending);
      expect(ApprovalStatusX.fromString(null), ApprovalStatus.pending);
      expect(ApprovalStatusX.fromString('bogus'), ApprovalStatus.pending);
    });
  });

  group('TournamentRegistration.fromJson', () {
    test('parses pending registration with nested tournament + category', () {
      final reg = TournamentRegistration.fromJson({
        'id': 7,
        'tournament_id': 3,
        'category_id': 5,
        'athlete_id': 9,
        'participation_type': 'team',
        'team_name': 'Elite Tigers',
        'payment_status': 'pending',
        'approval_status': 'pending',
        'status': 'pending',
        'tournament': {'id': 3, 'name': 'U-16 State Cup'},
        'category': {'id': 5, 'name': 'U-16'},
      });

      expect(reg.id, 7);
      expect(reg.isPending, isTrue);
      expect(reg.isApproved, isFalse);
      expect(reg.isRejected, isFalse);
      expect(reg.tournamentName, 'U-16 State Cup');
      expect(reg.categoryName, 'U-16');
      expect(reg.teamName, 'Elite Tigers');
    });

    test('parses approved and rejected registrations', () {
      final approved = TournamentRegistration.fromJson({
        'id': 1,
        'tournament_id': 1,
        'category_id': 1,
        'athlete_id': 1,
        'participation_type': 'individual',
        'approval_status': 'approved',
        'status': 'confirmed',
        'reviewed_by': 4,
        'reviewed_at': '2026-09-10T10:00:00.000000Z',
      });
      expect(approved.isApproved, isTrue);
      expect(approved.reviewedBy, 4);
      expect(approved.reviewedAt, isNotNull);

      final rejected = TournamentRegistration.fromJson({
        'id': 2,
        'tournament_id': 1,
        'category_id': 1,
        'athlete_id': 2,
        'participation_type': 'individual',
        'approval_status': 'rejected',
        'status': 'cancelled',
        'rejection_reason': 'Category is full',
      });
      expect(rejected.isRejected, isTrue);
      expect(rejected.rejectionReason, 'Category is full');
    });

    test('round-trips through toJson', () {
      final reg = TournamentRegistration.fromJson({
        'id': '11',
        'tournament_id': '2',
        'category_id': '3',
        'athlete_id': '4',
        'participation_type': 'individual',
        'approval_status': 'approved',
      });
      final json = reg.toJson();
      expect(json['approval_status'], 'approved');
      expect(TournamentRegistration.fromJson(json).isApproved, isTrue);
    });
  });

  group('TrialRegistration.fromJson', () {
    test('parses pending trial registration', () {
      final reg = TrialRegistration.fromJson({
        'id': 5,
        'trial_id': 2,
        'athlete_id': 9,
        'registration_ref': '#TR20260901-0001',
        'document_status': 'submitted',
        'verification_status': 'pending',
        'approval_status': 'pending',
        'trial': {'id': 2, 'name': 'U-14 Trials'},
      });

      expect(reg.registrationRef, '#TR20260901-0001');
      expect(reg.isPending, isTrue);
      expect(reg.trialName, 'U-14 Trials');
    });

    test('parses rejected trial registration with reason', () {
      final reg = TrialRegistration.fromJson({
        'id': 6,
        'trial_id': 2,
        'athlete_id': 10,
        'registration_ref': '#TR20260901-0002',
        'verification_status': 'rejected',
        'approval_status': 'rejected',
        'rejection_reason': 'No vacancies',
      });
      expect(reg.isRejected, isTrue);
      expect(reg.rejectionReason, 'No vacancies');
    });
  });
}
