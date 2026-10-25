import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/providers/role_config_provider.dart';
import 'package:sportx_app/theme/colors.dart';

/// Shared "Continue with Google" button.
///
/// The role must be captured *before* the button on sign-up — it drives
/// approval routing on the backend. On login the role is omitted.
class GoogleSignInButton extends ConsumerStatefulWidget {
  final String? role;
  final bool isSignUp;
  const GoogleSignInButton({super.key, this.role, this.isSignUp = false});

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _busy = false;

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // Web client id for backend audience check.
      // 1. Checked from --dart-define
      // 2. Checked from .env file (GOOGLE_SERVER_CLIENT_ID)
      // 3. Fallback to client_type 3 Web Client ID from google-services.json
      final envServerId = dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim() ?? '';
      const defineServerId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');
      final serverId = defineServerId.isNotEmpty
          ? defineServerId
          : (envServerId.isNotEmpty
              ? envServerId
              : '241021895160-6ei8d3apdg08od7veagg052scpsg0hfp.apps.googleusercontent.com');

      final google = GoogleSignIn(
        serverClientId: serverId,
        scopes: const ['email', 'profile'],
      );
      final account = await google.signIn();
      if (account == null) {
        // User dismissed the account picker — not an error.
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        if (mounted) {
          SnackBarUtils.showError(
            context,
            'Google sign-in is not configured on this device build yet.',
          );
        }
        return;
      }
      // Only send role on sign-up, not on login
      final roleToSend = widget.isSignUp ? widget.role : null;
      await ref
          .read(authProvider.notifier)
          .signInWithGoogle(idToken: idToken, role: roleToSend);
      if (!mounted) return;
      final state = ref.read(authProvider);
      if (state.status == AuthStatus.authenticated) {
        // Land on the active role's dashboard — not the athlete-only feed.
        context.go(ref.read(roleConfigProvider).homeRoute);
      } else if (state.status == AuthStatus.error) {
        _handleAuthError(state.error ?? 'Google sign-in failed');
      }
    } catch (e) {
      _handleGoogleSignInError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _handleGoogleSignInError(Object error) {
    if (!mounted) return;
    final errorStr = error.toString().toLowerCase();
    
    // Check for common Google Sign-In error patterns
    if (errorStr.contains('network') || errorStr.contains('connection') || errorStr.contains('socket')) {
      SnackBarUtils.showError(context, 'Network error. Please check your connection.');
    } else if (errorStr.contains('canceled') || errorStr.contains('cancelled') || errorStr.contains('user_canceled')) {
      // User dismissed — silent, not an error
    } else if (errorStr.contains('sign_in_failed') || errorStr.contains('signin_failed')) {
      SnackBarUtils.showError(context, 'Sign in failed. Please try again.');
    } else if (errorStr.contains('platform') || errorStr.contains('api_not_available')) {
      SnackBarUtils.showError(context, 'Google sign-in not available. Please try again.');
    } else if (errorStr.contains('developer_error') || errorStr.contains('invalid_client')) {
      SnackBarUtils.showError(context, 'Google sign-in configuration error. Please contact support.');
    } else {
      SnackBarUtils.showError(context, 'Google sign-in failed. Please try again.');
    }
  }

  void _handleAuthError(String error) {
    if (!mounted) return;
    final lower = error.toLowerCase();
    if (lower.contains('connection') || lower.contains('network') || lower.contains('timeout')) {
      SnackBarUtils.showError(context, 'Connection error. Please check your internet.');
    } else if (lower.contains('unauthorized') || lower.contains('invalid token') || lower.contains('token expired')) {
      SnackBarUtils.showError(context, 'Session expired. Please try again.');
    } else if (lower.contains('permission') || lower.contains('forbidden') || lower.contains('403')) {
      SnackBarUtils.showError(context, 'Access denied. Please contact support.');
    } else {
      SnackBarUtils.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _busy ? null : _signIn,
          icon: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'G',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
          label: Text(
            'Continue with Google',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ],
    );
  }
}
