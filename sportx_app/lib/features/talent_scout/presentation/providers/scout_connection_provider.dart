import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class ScoutConnectionStats {
  final int totalCount;
  final int acceptedCount;
  final int pendingCount;
  final int rejectedCount;

  const ScoutConnectionStats({
    this.totalCount = 0,
    this.acceptedCount = 0,
    this.pendingCount = 0,
    this.rejectedCount = 0,
  });
}

class ScoutConnectionState {
  final List<Map<String, dynamic>> connections;
  final ScoutConnectionStats stats;
  final bool isLoading;
  final String? error;

  ScoutConnectionState({
    this.connections = const [],
    this.stats = const ScoutConnectionStats(),
    this.isLoading = false,
    this.error,
  });

  ScoutConnectionState copyWith({
    List<Map<String, dynamic>>? connections,
    ScoutConnectionStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return ScoutConnectionState(
      connections: connections ?? this.connections,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ScoutConnectionNotifier extends StateNotifier<ScoutConnectionState> {
  final Dio _dio;

  ScoutConnectionNotifier(this._dio) : super(ScoutConnectionState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/me/connections');
      final list = List<Map<String, dynamic>>.from(resp.data['data'] ?? []);
      
      int accepted = 0;
      int pending = 0;
      int rejected = 0;
      for (final conn in list) {
        switch (conn['status']) {
          case 'accepted':
            accepted++;
            break;
          case 'pending':
            pending++;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }

      state = ScoutConnectionState(
        connections: list,
        stats: ScoutConnectionStats(
          totalCount: list.length,
          acceptedCount: accepted,
          pendingCount: pending,
          rejectedCount: rejected,
        ),
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<bool> sendConnectionRequest(String athleteId, {String? message}) async {
    try {
      await _dio.post('/athletes/$athleteId/connect', data: {'message': message});
      await load();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ApiException.fromDio(e).message);
      return false;
    }
  }

  Future<bool> cancelConnection(String connectionId) async {
    try {
      await _dio.delete('/me/connections/$connectionId');
      await load();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ApiException.fromDio(e).message);
      return false;
    }
  }
}

final scoutConnectionProvider = StateNotifierProvider<ScoutConnectionNotifier, ScoutConnectionState>((ref) {
  return ScoutConnectionNotifier(ref.watch(dioProvider));
});
