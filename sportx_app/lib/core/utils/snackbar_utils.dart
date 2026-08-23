import 'package:flutter/material.dart';
import 'package:sportx_app/theme/colors.dart';

class SnackBarUtils {
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showError(BuildContext context, dynamic error, [String? fallbackMessage]) {
    if (!context.mounted) return;
    String message = fallbackMessage ?? 'An unexpected error occurred';
    
    if (error is String) {
      message = error;
    } else if (error != null) {
      // Assuming ApiException overrides toString() to return user-friendly message
      message = error.toString().replaceFirst('Exception: ', '').replaceFirst('Failed: ', '');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
