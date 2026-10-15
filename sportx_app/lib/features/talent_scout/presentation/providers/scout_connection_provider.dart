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
  final List<Map<String, dynamic>> incoming;
  final ScoutConnectionStats stats;
  final bool isLoading;
  final String? error;

  ScoutConnectionState({
    this.connections = const [],
    this.incoming = const [],
    this.stats = const ScoutConnectionStats(),
    this.isLoading = false,
    this.error,
  });

  ScoutConnectionState copyWith({
    List<Map<String, dynamic>>? connections,
    List<Map<String, dynamic>>? incoming,
    ScoutConnectionStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return ScoutConnectionState(
      connections: connections ?? this.connections,
      incoming: incoming ?? this.incoming,
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
      final resp = await _dio.get('/me/scout-connections');
      if (!mounted) {
        return;
      }
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

      // Incoming athlete-initiated requests (two-way connect).
      List<Map<String, dynamic>> incoming = state.incoming;
      try {
        final inResp = await _dio.get('/me/scout-connections/incoming');
        if (!mounted) {
          return;
        }
        incoming = List<Map<String, dynamic>>.from(inResp.data['data'] ?? []);
      } catch (_) {
        // Non-fatal: older backend or no incoming.
      }

      if (mounted) {
        state = ScoutConnectionState(
        connections: list,
        incoming: incoming,
        stats: ScoutConnectionStats(
        totalCount: list.length,
        acceptedCount: accepted,
        pendingCount: pending,
        rejectedCount: rejected,
        ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
        }
    }
  }

  Future<bool> sendConnectionRequest(String athleteId, {String? message}) async {
    try {
      await _dio.post('/athletes/$athleteId/connect', data: {'message': message});
      if (!mounted) {
        return false;
      }
      await load();
      if (!mounted) {
        return false;
      }
      return true;
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(error: ApiException.fromDio(e).message);
      }
      return false;
    }
  }

  Future<bool> cancelConnection(String connectionId) async {
    try {
      await _dio.delete('/me/scout-connections/$connectionId');
      if (!mounted) {
        return false;
      }
      await load();
      if (!mounted) {
        return false;
      }
      return true;
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(error: ApiException.fromDio(e).message);
      }
      return false;
    }
  }

  /// Accept an athlete-initiated request (scout side, two-way connect).
  Future<bool> acceptIncoming(String connectionId) async {
    try {
      await _dio.post('/me/scout-connections/$connectionId/accept');
      if (!mounted) {
        return false;
      }
      await load();
      if (!mounted) {
        return false;
      }
      return true;
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(error: ApiException.fromDio(e).message);
      }
      return false;
    }
  }

  /// Reject an athlete-initiated request (scout side).
  Future<bool> rejectIncoming(String connectionId) async {
    try {
      await _dio.post('/me/scout-connections/$connectionId/reject');
      if (!mounted) {
        return false;
      }
      await load();
      if (!mounted) {
        return false;
      }
      return true;
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(error: ApiException.fromDio(e).message);
      }
      return false;
    }
  }
}

final scoutConnectionProvider = StateNotifierProvider<ScoutConnectionNotifier, ScoutConnectionState>((ref) {
  return ScoutConnectionNotifier(ref.watch(dioProvider));
});
