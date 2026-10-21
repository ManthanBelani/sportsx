import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

/// Result of a "Register" tap on a tournament that uses an external
/// registration page.
class ExternalRegistrationResult {
  final bool opened;
  final bool counted;
  final String? error;

  const ExternalRegistrationResult({
    required this.opened,
    this.counted = false,
    this.error,
  });
}

/// Records clicks on a tournament's external "Register" button.
///
/// The backend dedupes on (tournament_id, click_token), so the same token can
/// safely be retried — a re-render or a duplicated API call can never inflate
/// the counter. A new token is minted per user action.
class ExternalRegistrationRecorder {
  final Dio _dio;

  ExternalRegistrationRecorder(this._dio);

  /// Generates a short random token used as the idempotency key.
  static String newToken() {
    final random = Random.secure();
    final part = List.generate(8, (_) => random.nextInt(36).toRadixString(36)).join();
    return '${DateTime.now().microsecondsSinceEpoch}-$part';
  }

  /// Sends the click to the backend. Returns true when the counter moved.
  Future<bool> record(String tournamentId, {String? clickToken}) async {
    try {
      final resp = await _dio.post(
        '/tournaments/$tournamentId/registration-click',
        data: {'click_token': clickToken ?? newToken()},
      );
      final data = resp.data is Map ? resp.data['data'] : null;
      if (data is Map && data['incremented'] != null) {
        return data['incremented'] == true;
      }
      return true;
    } on DioException {
      // Counting is best-effort: a failure here must never stop the user
      // from reaching the external registration page.
      return false;
    }
  }
}

final externalRegistrationRecorderProvider =
    Provider<ExternalRegistrationRecorder>((ref) {
  return ExternalRegistrationRecorder(ref.watch(dioProvider));
});
