import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

/// Phase 7 observations (v3 SC.10) + athlete contact (v3 SC.13).
/// Backend: GET/POST /observations, POST /athletes/{id}/contact.

final observationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, athleteProfileId) async {
  final resp = await ref.watch(dioProvider).get('/observations',
      queryParameters: athleteProfileId == null ? null : {'athlete_profile_id': athleteProfileId});
  final body = resp.data;
  final list = body is Map && body['data'] is List ? body['data'] as List : (body is List ? body : []);
  return list.cast<Map<String, dynamic>>();
});

Future<Map<String, dynamic>?> addObservation(
  WidgetRef ref, {
  required String athleteProfileId,
  int? rating,
  String? note,
}) async {
  try {
    final resp = await ref.read(dioProvider).post('/observations', data: {
      'athlete_profile_id': int.parse(athleteProfileId),
      if (rating != null) 'rating': rating,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    ref.invalidate(observationsProvider(null));
    ref.invalidate(observationsProvider(athleteProfileId));
    return resp.data['data'] as Map<String, dynamic>?;
  } on DioException {
    return null;
  }
}

/// Returns {connection, is_minor, guardian_review}. Minor → guardian notified,
/// chat still gated on guardian consent server-side.
Future<Map<String, dynamic>?> contactAthlete(
  WidgetRef ref, {
  required String athleteProfileId,
  required String purpose,
}) async {
  try {
    final resp = await ref
        .read(dioProvider)
        .post('/athletes/$athleteProfileId/contact', data: {'purpose': purpose});
    return resp.data['data'] as Map<String, dynamic>?;
  } on DioException {
    return null;
  }
}
