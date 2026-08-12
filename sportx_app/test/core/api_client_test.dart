import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/core/utils/api_client.dart';

DioException _badResponse(Map<String, dynamic> data, int status) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, data: data, statusCode: status),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  group('ApiException.fromDio', () {
    test('parses field-level 422 errors (regression: B8)', () {
      final api = ApiException.fromDio(_badResponse({
        'message': 'The given data was invalid.',
        'errors': {
          'email': ['The email has already been taken.'],
          'password': ['The password field is required.'],
        },
      }, 422));

      expect(api.statusCode, 422);
      expect(api.fieldErrors['email'], 'The email has already been taken.');
      expect(api.fieldErrors['password'], contains('required'));
    });

    test('handles 403 error-as-map without crashing (regression: B9)', () {
      // EnsureRole returns { "message": "...", "error": { "code": ..., "message": "..." } }.
      final api = ApiException.fromDio(_badResponse({
        'message': 'Insufficient permissions',
        'error': {'code': 'FORBIDDEN', 'message': 'Insufficient permissions'},
      }, 403));

      expect(api.statusCode, 403);
      expect(api.message, 'Insufficient permissions');
    });

    test('falls back to a generic server message when no parseable body', () {
      final api = ApiException.fromDio(_badResponse({}, 500));

      expect(api.statusCode, 500);
      expect(api.message, contains('500'));
      expect(api.fieldErrors, isEmpty);
    });
  });
}
