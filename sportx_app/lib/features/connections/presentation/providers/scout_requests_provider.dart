import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

/// Incoming talent-scout connection requests for the authenticated athlete.
/// Backed by GET /me/scout-connection-requests (role: athlete).
class ScoutRequestState {
  final List<Map<String, dynamic>> requests;
  final bool isLoading;
  final String? error;

  ScoutRequestState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  int get pendingCount =>
      requests.where((r) => (r['status'] ?? 'pending') == 'pending').length;

  ScoutRequestState copyWith({
    List<Map<String, dynamic>>? requests,
    bool? isLoading,
    String? error,
  }) {
    return ScoutRequestState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ScoutRequestNotifier extends StateNotifier<ScoutRequestState> {
  final Dio _dio;

  ScoutRequestNotifier(this._dio) : super(ScoutRequestState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/me/scout-connection-requests');
      final list = List<Map<String, dynamic>>.from(resp.data['data'] ?? []);
      state = ScoutRequestState(requests: list);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<bool> accept(String connectionId) async {
    try {
      await _dio.post('/me/scout-connection-requests/$connectionId/accept');
      await load();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ApiException.fromDio(e).message);
      return false;
    }
  }

  Future<bool> reject(String connectionId) async {
    try {
      await _dio.post('/me/scout-connection-requests/$connectionId/reject');
      await load();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ApiException.fromDio(e).message);
      return false;
    }
  }
}

final scoutRequestsProvider =
    StateNotifierProvider<ScoutRequestNotifier, ScoutRequestState>((ref) {
  return ScoutRequestNotifier(ref.watch(dioProvider));
});
