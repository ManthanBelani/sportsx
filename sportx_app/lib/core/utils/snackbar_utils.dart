import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';

class SnackBarUtils {
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showError(BuildContext context, dynamic error, [String? fallbackMessage]) {
    if (!context.mounted) return;
    final message = _resolveMessage(error, fallbackMessage);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows field validation errors inline via snackbar. If [fieldErrors] is
  /// non-empty, shows the first field error; otherwise falls back to [error].
  static void showValidationError(BuildContext context, Map<String, String> fieldErrors, dynamic error, [String? fallback]) {
    if (fieldErrors.isNotEmpty) {
      showError(context, fieldErrors.values.first, fallback);
    } else {
      showError(context, error, fallback);
    }
  }

  static String _resolveMessage(dynamic error, String? fallback) {
    if (error == null) return fallback ?? 'An unexpected error occurred. Please try again.';
    if (error is String) {
      final trimmed = error.trim();
      if (trimmed.isEmpty) return fallback ?? 'An unexpected error occurred. Please try again.';
      return trimmed;
    }
    if (error is DioException) {
      return ApiException.fromDio(error).message;
    }
    if (error is ApiException) {
      return error.message;
    }
    final raw = error.toString().trim();
    if (raw.isEmpty) return fallback ?? 'An unexpected error occurred. Please try again.';
    // Strip common prefixes injected by Dart / Dio.
    var cleaned = raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^FormatException:\s*'), '')
        .replaceFirst(RegExp(r'^DioException.*?:\s*'), '')
        .replaceFirst(RegExp(r'^ApiException.*?:\s*'), '');
    cleaned = cleaned.trim();
    if (cleaned.isEmpty) return fallback ?? 'An unexpected error occurred. Please try again.';
    // Dio often includes verbose stack traces after newline — keep first line only for snackbar.
    final firstLine = cleaned.split('\n').first.trim();
    if (firstLine.length > 220) return '${firstLine.substring(0, 217)}...';
    return firstLine;
  }
}
