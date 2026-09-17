import 'package:dio/dio.dart';
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

  String _msg(Object e) => e is DioException ? ApiException.fromDio(e).message : ApiException.messageFor(e);

  Future<(bool, String?)> enroll({required int coachId, required String planType, String? notes}) async {
    try {
      await _ref.read(dioProvider).post('/coaches/$coachId/enroll', data: {'plan_type': planType, 'notes': notes});
      _ref.invalidate(myCoachingEnrollmentsProvider);
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  // Back-compat boolean wrapper used by existing screens.
  Future<bool> enrollLegacy({required int coachId, required String planType, String? notes}) async {
    final (ok, _) = await enroll(coachId: coachId, planType: planType, notes: notes);
    return ok;
  }

  Future<(bool, String?)> approve(String enrollmentId, {required DateTime startDate, DateTime? endDate, String? coachResponse}) async {
    try {
      await _ref.read(dioProvider).patch('/coaching-enrollments/$enrollmentId/approve', data: {
        'start_date': startDate.toIso8601String().split('T').first,
        if (endDate != null) 'end_date': endDate.toIso8601String().split('T').first,
        if (coachResponse != null) 'coach_response': coachResponse,
      });
      _ref.invalidate(coachEnrollmentsProvider);
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  Future<(bool, String?)> reject(String enrollmentId, String reason) async {
    try {
      await _ref.read(dioProvider).patch('/coaching-enrollments/$enrollmentId/reject', data: {'rejection_reason': reason});
      _ref.invalidate(coachEnrollmentsProvider);
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }
}

final coachingEnrollmentActionsProvider = Provider((ref) => CoachingEnrollmentActions(ref));
