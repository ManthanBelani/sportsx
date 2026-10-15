import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class ReportNotifier extends StateNotifier<AsyncValue<void>> {
  final Dio _dio;
  ReportNotifier(this._dio) : super(const AsyncValue.data(null));

  Future<bool> report({
    required String reportableType,
    required int reportableId,
    required String reason,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dio.post('/reports', data: {
        'reportable_type': reportableType,
        'reportable_id': reportableId,
        'reason': reason,
        'description': ?description,
      });
      if (!mounted) {
        return false;
      }
      if (mounted) {
        state = const AsyncValue.data(null);
      }
      return true;
    } on DioException catch (e) {
      if (mounted) {
        state = AsyncValue.error(ApiException.fromDio(e), StackTrace.current);
      }
      return false;
    }
  }
}

final reportProvider = StateNotifierProvider<ReportNotifier, AsyncValue<void>>((ref) {
  return ReportNotifier(ref.watch(dioProvider));
});
