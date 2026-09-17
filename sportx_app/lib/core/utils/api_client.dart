import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/config/api_config.dart';
import 'package:sportx_app/core/utils/storage_service.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    sendTimeout: ApiConfig.connectTimeout,
    headers: {'Accept': 'application/json'},
  ));

  dio.interceptors.add(AuthInterceptor(ref));
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: false,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ));
  }

  dio.options.validateStatus = (status) => status != null && status >= 200 && status < 300;

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
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final storage = ref.read(storageServiceProvider);
      await storage.deleteToken();
      try {
        ref.read(authProvider.notifier).forceLogout();
      } catch (_) {}
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
        msg = 'Connection timed out. Please check your internet connection and try again.';
        break;
      case DioExceptionType.connectionError:
        msg = 'No internet connection. Please check your network and try again.';
        break;
      case DioExceptionType.cancel:
        msg = 'Request was cancelled. Please try again.';
        break;
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        if (data is Map) {
          if (data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
            msg = data['message'] as String;
          } else if (data['error'] is String && (data['error'] as String).trim().isNotEmpty) {
            msg = data['error'] as String;
          } else if (data['error'] is Map && data['error']['message'] is String) {
            msg = data['error']['message'] as String;
          } else {
            msg = _statusMessage(status);
          }
          final errs = data['errors'];
          if (errs is Map) {
            fieldErrors = {
              for (final entry in errs.entries)
                entry.key.toString(): entry.value is List
                    ? (entry.value as List).map((v) => v.toString()).join(' ')
                    : entry.value.toString(),
            };
            // If we only have field errors and generic message, surface first field error.
            if (msg == _statusMessage(status) && fieldErrors.isNotEmpty) {
              msg = fieldErrors.values.first;
            }
          }
          // Append validation details when message is generic.
          if (fieldErrors.isNotEmpty && msg.toLowerCase().contains('validation')) {
            msg = '${msg}: ${fieldErrors.values.join(', ')}';
          }
        } else if (data is String && data.trim().isNotEmpty) {
          msg = data.trim();
        } else {
          msg = _statusMessage(status);
        }
        break;
      case DioExceptionType.badCertificate:
        msg = 'Secure connection failed. Please try again later.';
        break;
      case DioExceptionType.unknown:
      default:
        // Covers socket exceptions, format errors, and unknown Dio types.
        final errStr = e.error?.toString().toLowerCase() ?? '';
        final msgStr = e.message?.toLowerCase() ?? '';
        if (errStr.contains('socketexception') || msgStr.contains('socketexception') || errStr.contains('network is unreachable')) {
          msg = 'No internet connection. Please check your network and try again.';
        } else if (errStr.contains('handshake') || errStr.contains('certificate')) {
          msg = 'Secure connection failed. Please try again later.';
        } else if (e.response != null) {
          msg = _statusMessage(e.response?.statusCode);
        } else {
          msg = 'Something went wrong. Please try again.';
        }
    }
    return ApiException(
      message: msg,
      statusCode: e.response?.statusCode,
      data: e.response?.data,
      fieldErrors: fieldErrors,
    );
  }

  static String _statusMessage(int? status) {
    switch (status) {
      case 400:
        return 'Bad request. Please check your input and try again.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You don\'t have permission to perform this action.';
      case 404:
        return 'Requested resource not found.';
      case 405:
        return 'Action not allowed.';
      case 409:
        return 'Conflict — this action was already performed or data already exists.';
      case 413:
        return 'File too large. Please choose a smaller file.';
      case 422:
        return 'Validation failed. Please check your input.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
      case 503:
      case 504:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        if (status != null) return 'Request failed (error $status). Please try again.';
        return 'Something went wrong. Please try again.';
    }
  }

  /// Maps any thrown object to a user-friendly message. Never leaks raw
  /// stack traces, Dio internals, or type-cast errors to the user.
  static String messageFor(Object error) {
    if (error is DioException) return ApiException.fromDio(error).message;
    if (error is ApiException) return error.message;
    final raw = error.toString();
    final lower = raw.toLowerCase();
    // Technical Dart/Flutter errors that must not leak verbatim.
    if (lower.contains('socketexception') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection timed out') ||
        lower.contains('handshake') ||
        lower.contains('certificate') ||
        lower.contains('is not a subtype of type') ||
        lower.contains('type cast') ||
        lower.contains('type \'string\' is not') ||
        lower.contains('null check operator used on a null value') ||
        lower.contains('dioexception') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('failed host lookup')) {
      // Classify broadly without exposing internals.
      if (lower.contains('socketexception') ||
          lower.contains('network is unreachable') ||
          lower.contains('connection refused') ||
          lower.contains('failed host lookup') ||
          lower.contains('xmlhttprequest')) {
        return 'No internet connection. Please check your network and try again.';
      }
      if (lower.contains('is not a subtype') || lower.contains('type cast') || lower.contains('null check operator')) {
        return 'Failed to load data. Please try again.';
      }
      return 'Something went wrong. Please try again.';
    }
    // Strip common Dart exception prefixes.
    var cleaned = raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^FormatException:\s*'), '')
        .replaceFirst(RegExp(r'^StateError:\s*'), '')
        .replaceFirst(RegExp(r'^RangeError[^:]*:\s*'), '')
        .trim();
    // Dio often includes verbose suffix after newline/stack — keep first line only.
    cleaned = cleaned.split('\n').first.trim();
    // Remove "DioException [DioExceptionType.xxx]: " prefix if leaked as string.
    cleaned = cleaned.replaceFirst(RegExp(r'^DioException[^:]*:\s*'), '').trim();
    if (cleaned.isEmpty) return 'Something went wrong. Please try again.';
    // Clamp overly long technical messages.
    if (cleaned.length > 180) return '${cleaned.substring(0, 177)}...';
    // If still looks like a raw HTTP/html dump, sanitize.
    if (cleaned.startsWith('<!DOCTYPE') || cleaned.startsWith('<html')) {
      return 'Server error. Please try again later.';
    }
    return cleaned;
  }

  @override
  String toString() => message;
}
