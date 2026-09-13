import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

/// Organizer's own tournaments (GET /me/tournaments).
final myTournamentsProvider =
    StateNotifierProvider<DirectoryNotifier<Tournament>, DirectoryState<Tournament>>((ref) {
  return DirectoryNotifier<Tournament>(ref.watch(dioProvider), '/me/tournaments', Tournament.fromJson);
});

/// Registrations for a tournament (GET /tournaments/{id}/registrations).
final tournamentRegistrationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tournamentId) async {
  final resp = await ref.watch(dioProvider).get('/tournaments/$tournamentId/registrations');
  final data = resp.data['data'];
  return List<Map<String, dynamic>>.from(data as List);
});

/// Results for a tournament (GET /tournaments/{id}/results).
final tournamentResultsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tournamentId) async {
  final resp = await ref.watch(dioProvider).get('/tournaments/$tournamentId/results');
  final data = resp.data['data'];
  return List<Map<String, dynamic>>.from(data as List);
});

/// Capacity for a tournament (GET /tournaments/{id}/capacity).
final tournamentCapacityProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tournamentId) async {
  final resp = await ref.watch(dioProvider).get('/tournaments/$tournamentId/capacity');
  final data = resp.data['data'];
  return List<Map<String, dynamic>>.from(data as List);
});

class ProviderTournamentActions {
  final Dio _dio;
  final Ref _ref;
  ProviderTournamentActions(this._dio, this._ref);

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      await _dio.post('/me/tournaments', data: data);
      _ref.read(myTournamentsProvider.notifier).refresh();
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> publish(String id) async {
    try {
      await _dio.post('/me/tournaments/$id/publish');
      _ref.read(myTournamentsProvider.notifier).refresh();
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> close(String id) async {
    try {
      await _dio.post('/me/tournaments/$id/close');
      _ref.read(myTournamentsProvider.notifier).refresh();
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> publishResult(String tournamentId, String resultId) async {
    try {
      await _dio.post('/tournaments/$tournamentId/results/$resultId/publish');
      _ref.invalidate(tournamentResultsProvider(tournamentId));
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> unpublishResult(String tournamentId, String resultId) async {
    try {
      await _dio.post('/tournaments/$tournamentId/results/$resultId/unpublish');
      _ref.invalidate(tournamentResultsProvider(tournamentId));
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> updatePayment(String registrationId, String paymentStatus) async {
    try {
      await _dio.patch('/registrations/tournaments/$registrationId/payment', data: {'payment_status': paymentStatus});
      return true;
    } on DioException {
      return false;
    }
  }

  Future<String?> downloadTournamentIcs(String registrationId) async {
    try {
      final resp = await _dio.get('/registrations/tournaments/$registrationId/ics');
      // Backend returns text/calendar body directly; we return it as string
      return resp.data is String ? resp.data as String : resp.data.toString();
    } on DioException {
      return null;
    }
  }
}

final providerTournamentActionsProvider = Provider<ProviderTournamentActions>((ref) {
  return ProviderTournamentActions(ref.watch(dioProvider), ref);
});
