import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

/// Athlete-facing directory of talent scouts (two-way discovery).
/// Backed by GET /scouts (role: athlete).
class ScoutDirectoryState {
  final List<Map<String, dynamic>> scouts;
  final bool isLoading;
  final String? error;

  ScoutDirectoryState({this.scouts = const [], this.isLoading = false, this.error});

  ScoutDirectoryState copyWith({List<Map<String, dynamic>>? scouts, bool? isLoading, String? error}) {
    return ScoutDirectoryState(
      scouts: scouts ?? this.scouts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ScoutDirectoryNotifier extends StateNotifier<ScoutDirectoryState> {
  final Dio _dio;

  ScoutDirectoryNotifier(this._dio) : super(ScoutDirectoryState()) {
    load();
  }

  Future<void> load({String? query}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/scouts', queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
      });
      if (!mounted) {
        return;
      }
      final body = resp.data;
      final List list = body is Map && body['data'] is List ? body['data'] as List : (body is List ? body : []);
      if (mounted) {
        state = ScoutDirectoryState(scouts: list.cast<Map<String, dynamic>>().map((e) => Map<String, dynamic>.from(e)).toList());
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

  /// Athlete -> scout connect request. POST /scouts/{scout}/connect
  Future<bool> connect(String scoutId, {String? message}) async {
    try {
      await _dio.post('/scouts/$scoutId/connect', data: {'message': message});
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

final scoutDirectoryProvider = StateNotifierProvider<ScoutDirectoryNotifier, ScoutDirectoryState>((ref) {
  return ScoutDirectoryNotifier(ref.watch(dioProvider));
});
