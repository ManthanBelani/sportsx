import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/config/api_config.dart';
import 'package:sportx_app/core/utils/storage_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));

  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
  ));

  return dio;
});

class AuthInterceptor extends Interceptor {
  final Ref ref;

  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final storage = ref.read(storageServiceProvider);
    final token = await storage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid — clear storage
      ref.read(storageServiceProvider).deleteToken();
    }
    handler.next(err);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  /// Per-field validation messages, e.g. {"email": "The email has already been taken."}.
  final Map<String, String> fieldErrors;

  ApiException({required this.message, this.statusCode, this.data, this.fieldErrors = const {}});

  factory ApiException.fromDio(DioException e) {
    String msg;
    Map<String, String> fieldErrors = const {};
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        msg = 'Connection timed out. Please check your internet.';
        break;
      case DioExceptionType.connectionError:
        msg = 'No internet connection.';
        break;
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map) {
          if (data['message'] is String) {
            msg = data['message'];
          } else if (data['error'] is String) {
            msg = data['error'];
          } else if (data['error'] is Map && data['error']['message'] is String) {
            // e.g. EnsureRole: { "error": { "code": "FORBIDDEN", "message": "…" } }
            msg = data['error']['message'];
          } else {
            msg = 'Server error: ${e.response?.statusCode}';
          }
          // Laravel 422 shape: { "message": …, "errors": { "field": ["…","…"] } }
          final errs = data['errors'];
          if (errs is Map) {
            fieldErrors = {
              for (final entry in errs.entries)
                entry.key.toString(): entry.value is List
                    ? (entry.value as List).map((e) => e.toString()).join(' ')
                    : entry.value.toString(),
            };
          }
        } else {
          msg = 'Server error: ${e.response?.statusCode}';
        }
        break;
      default:
        msg = 'Something went wrong. Please try again.';
    }
    return ApiException(
      message: msg,
      statusCode: e.response?.statusCode,
      data: e.response?.data,
      fieldErrors: fieldErrors,
    );
  }

  @override
  String toString() => message;
}
