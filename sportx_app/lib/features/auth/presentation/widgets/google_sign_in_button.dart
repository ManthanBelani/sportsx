import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/theme/colors.dart';

/// Shared "Continue with Google" button (Phase 1).
///
/// The role must be captured *before* the button on sign-up — it drives
/// approval routing on the backend. On login the role is omitted.
class GoogleSignInButton extends ConsumerStatefulWidget {
  final String? role;
  const GoogleSignInButton({super.key, this.role});

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _busy = false;

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // Web client id for backend audience check. Provision via
      // --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id> (Google Cloud
      // console → Web OAuth client). Empty in dev → native flow still attempted.
      const serverId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');
      final google = GoogleSignIn(serverClientId: serverId.isEmpty ? null : serverId);
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
      await ref
          .read(authProvider.notifier)
          .signInWithGoogle(idToken: idToken, role: widget.role);
      if (!mounted) return;
      final state = ref.read(authProvider);
      if (state.status == AuthStatus.authenticated) {
        context.go('/home');
      } else if (state.status == AuthStatus.error) {
        SnackBarUtils.showError(context, state.error ?? 'Google sign-in failed');
      }
    } catch (_) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Google sign-in failed. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
