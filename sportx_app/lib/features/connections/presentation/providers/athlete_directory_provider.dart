import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

/// Athlete-to-athlete peer directory.
/// Backed by GET /athletes (now open to role:athlete, self excluded server-side).
class AthleteDirectoryState {
  final List<Map<String, dynamic>> athletes;
  final bool isLoading;
  final String? error;

  AthleteDirectoryState({this.athletes = const [], this.isLoading = false, this.error});

  AthleteDirectoryState copyWith({List<Map<String, dynamic>>? athletes, bool? isLoading, String? error}) {
    return AthleteDirectoryState(
      athletes: athletes ?? this.athletes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AthleteDirectoryNotifier extends StateNotifier<AthleteDirectoryState> {
  final Dio _dio;

  AthleteDirectoryNotifier(this._dio) : super(AthleteDirectoryState()) {
    load();
  }

  Future<void> load({String? query}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/athletes', queryParameters: {
        'per_page': 20,
        if (query != null && query.isNotEmpty) 'q': query,
      });
      if (!mounted) {
        return;
      }
      final body = resp.data;
      final List list = body is Map && body['data'] is List ? body['data'] as List : (body is List ? body : []);
      if (mounted) {
        state = AthleteDirectoryState(
        athletes: list.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
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

  /// Peer connect request. POST /me/connections/request {user_id}
  /// Returns null on success, error message otherwise.
  Future<String?> connect(int userId) async {
    try {
      await _dio.post('/me/connections/request', data: {'user_id': userId});
      if (!mounted) {
        return null;
      }
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message']?.toString();
      return msg ?? ApiException.fromDio(e).message;
    }
  }
}

final athleteDirectoryProvider = StateNotifierProvider<AthleteDirectoryNotifier, AthleteDirectoryState>((ref) {
  return AthleteDirectoryNotifier(ref.watch(dioProvider));
});
