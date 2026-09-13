import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

/// The signed-in academy's own profile (GET /me/academy).
final myAcademyProvider = FutureProvider<Academy>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/academy');
  final body = resp.data;
  final data = body is Map && body['data'] is Map
      ? body['data'] as Map<String, dynamic>
      : body as Map<String, dynamic>;
  return Academy.fromJson(data);
});

/// The signed-in academy's posted trials (GET /me/trials).
final myTrialsProvider =
    StateNotifierProvider<DirectoryNotifier<Trial>, DirectoryState<Trial>>((ref) {
  return DirectoryNotifier<Trial>(ref.watch(dioProvider), '/me/trials', Trial.fromJson);
});

/// Registrants for a specific trial (GET /trials/{id}/registrations).
final trialRegistrantsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, trialId) async {
  final resp = await ref.watch(dioProvider).get('/trials/$trialId/registrations');
  final data = resp.data['data'];
  return List<Map<String, dynamic>>.from(data as List);
});

/// Trial lifecycle actions for the academy/coach provider.
class ProviderTrialActions {
  final Dio _dio;
  final Ref _ref;
  ProviderTrialActions(this._dio, this._ref);

  /// Creates a trial. Throws [DioException] on failure so callers can surface
  /// the API's validation message.
  Future<void> create(Map<String, dynamic> data) async {
    await _dio.post('/me/trials', data: data);
    _ref.read(myTrialsProvider.notifier).refresh();
  }

  Future<bool> publish(String id) async {
    try {
      await _dio.post('/me/trials/$id/publish');
      _ref.read(myTrialsProvider.notifier).refresh();
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> close(String id) async {
    try {
      await _dio.post('/me/trials/$id/close');
      _ref.read(myTrialsProvider.notifier).refresh();
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> toggleReminder(String registrationId) async {
    try {
      await _dio.post('/registrations/trials/$registrationId/reminder');
      return true;
    } on DioException {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getTrialRegistration(String registrationId) async {
    try {
      final resp = await _dio.get('/registrations/trials/$registrationId');
      return resp.data['data'] as Map<String, dynamic>?;
    } on DioException {
      return null;
    }
  }

  Future<String?> downloadTrialIcs(String registrationId) async {
    try {
      final resp = await _dio.get('/registrations/trials/$registrationId/ics');
      return resp.data is String ? resp.data as String : resp.data.toString();
    } on DioException {
      return null;
    }
  }
}

final providerTrialActionsProvider = Provider<ProviderTrialActions>((ref) {
  return ProviderTrialActions(ref.watch(dioProvider), ref);
});
