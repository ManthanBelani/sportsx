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
  group('ApiException — nested validation envelope', () {
    test('reads field errors nested inside the error envelope', () {
      // The API wraps validation failures as
      // {error: {code, message, errors: {field: [messages]}}}.
      final api = ApiException.fromDio(_badResponse({
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'The given data was invalid.',
          'errors': {
            'external_registration_url': [
              'The external registration URL must be a valid link starting with http:// or https://.',
            ],
          },
        },
      }, 422));

      expect(api.statusCode, 422);
      expect(api.fieldErrors['external_registration_url'], contains('http'));
      expect(api.message, contains('external registration URL'));
    });
  });
}
