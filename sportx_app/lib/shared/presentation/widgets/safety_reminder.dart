import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/profile_provider.dart';
import 'package:sportx_app/theme/colors.dart';

/// Determines if the current user is a minor (under 18) based on their profile DOB.
class MinorStatusProvider {
  static Future<bool> isCurrentUserMinor(Ref ref) async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return false;

    final dob = profile['date_of_birth'] as String?;
    if (dob == null || dob.isEmpty) return false;

    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age < 18;
    } catch (_) {
      return false;
    }
  }
}

/// A provider that caches the minor status to avoid repeated API calls.
final isMinorProvider = FutureProvider<bool>((ref) async {
  return MinorStatusProvider.isCurrentUserMinor(ref);
});

/// Safety reminder dialog shown before minors engage in social features.
/// Call [showSafetyReminder] before allowing chat, media upload, or post creation.
Future<bool> showSafetyReminder(
  BuildContext context, {
  required String feature,
  String? customMessage,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _SafetyReminderDialog(
      feature: feature,
      customMessage: customMessage,
    ),
  );
  return result ?? false;
}

class _SafetyReminderDialog extends StatelessWidget {
  final String feature;
  final String? customMessage;

  const _SafetyReminderDialog({
    required this.feature,
    this.customMessage,
  });

  String _getFeatureTitle() {
    switch (feature) {
      case 'chat':
        return 'Start a Conversation';
      case 'media':
        return 'Share Photos or Media';
      case 'post':
        return 'Create a Post';
      case 'profile':
        return 'Share Profile Information';
      default:
        return 'Use Social Features';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.shieldAlert, size: 22, color: AppColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Safety Reminder',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Before you proceed with ${_getFeatureTitle().toLowerCase()}, please remember:',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.info, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Text(
                      'Online Safety Tips',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _safetyTip('Only connect with people you know in real life.'),
                _safetyTip('Never share personal info (address, phone, school, passwords).'),
                _safetyTip('Tell a trusted adult if someone makes you uncomfortable.'),
                _safetyTip('You can block or report anyone at any time.'),
                _safetyTip('Photos shared online can be saved and shared by others.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (customMessage != null)
            Text(
              customMessage!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Not Now',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'I Understand, Continue',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _safetyTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.checkCircle, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.dark, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// A wrapper widget that shows the safety reminder before executing an action.
/// Usage:
/// ```dart
/// SafetyReminderGate(
///   feature: 'chat',
///   child: () => navigateToChat(),
/// )
/// ```
class SafetyReminderGate extends ConsumerWidget {
  final String feature;
  final Future<void> Function() onConfirmed;
  final String? customMessage;
  final Widget? fallbackChild;

  const SafetyReminderGate({
    super.key,
    required this.feature,
    required this.onConfirmed,
    this.customMessage,
    this.fallbackChild,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMinorAsync = ref.watch(isMinorProvider);

    return isMinorAsync.when(
      loading: () => fallbackChild ?? const SizedBox.shrink(),
      error: (_, __) => fallbackChild ?? const SizedBox.shrink(),
      data: (isMinor) {
        if (!isMinor) {
          return fallbackChild ??
              TextButton(
                onPressed: () => onConfirmed(),
                child: Text('Proceed'),
              );
        }

        return TextButton(
          onPressed: () async {
            final confirmed = await showSafetyReminder(
              context,
              feature: feature,
              customMessage: customMessage,
            );
            if (confirmed && context.mounted) {
              await onConfirmed();
            }
          },
          child: fallbackChild ??
              Text(
                _getActionLabel(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
        );
      },
    );
  }

  String _getActionLabel() {
    switch (feature) {
      case 'chat':
        return 'Start Chat';
      case 'media':
        return 'Share Media';
      case 'post':
        return 'Create Post';
      case 'profile':
        return 'Update Profile';
      default:
        return 'Continue';
    }
  }
}