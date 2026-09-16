import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/models/coaching_enrollment.dart';

final coachEnrollmentsProvider = FutureProvider.family<List<CoachingEnrollment>, String?>((ref, status) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('/coach/enrollments', queryParameters: status != null ? {'approval_status': status} : null);
  final list = resp.data['data'] as List;
  return list.map((e) => CoachingEnrollment.fromJson(Map<String, dynamic>.from(e as Map))).toList();
});

final myCoachingEnrollmentsProvider = FutureProvider<List<CoachingEnrollment>>((ref) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('/me/coaching-enrollments');
  final list = resp.data['data'] as List;
  return list.map((e) => CoachingEnrollment.fromJson(Map<String, dynamic>.from(e as Map))).toList();
});

class CoachingEnrollmentActions {
  final Ref _ref;
  CoachingEnrollmentActions(this._ref);

  Future<bool> enroll({required int coachId, required String planType, String? notes}) async {
    try {
      await _ref.read(dioProvider).post('/coaches/$coachId/enroll', data: {'plan_type': planType, 'notes': notes});
      _ref.invalidate(myCoachingEnrollmentsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> approve(String enrollmentId, {required DateTime startDate, DateTime? endDate, String? coachResponse}) async {
    try {
      await _ref.read(dioProvider).patch('/coaching-enrollments/$enrollmentId/approve', data: {
        'start_date': startDate.toIso8601String().split('T').first,
        if (endDate != null) 'end_date': endDate.toIso8601String().split('T').first,
        if (coachResponse != null) 'coach_response': coachResponse,
      });
      _ref.invalidate(coachEnrollmentsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reject(String enrollmentId, String reason) async {
    try {
      await _ref.read(dioProvider).patch('/coaching-enrollments/$enrollmentId/reject', data: {'rejection_reason': reason});
      _ref.invalidate(coachEnrollmentsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final coachingEnrollmentActionsProvider = Provider((ref) => CoachingEnrollmentActions(ref));
