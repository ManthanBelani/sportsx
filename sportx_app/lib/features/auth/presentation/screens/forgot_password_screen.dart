import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/shared/providers/role_config_provider.dart';
import 'package:sportx_app/theme/colors.dart';

/// A.6 Forgot / Reset Password.
/// Step 1: request a reset code by email. Step 2: enter the code + new password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

enum _Step { request, reset, done }

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  _Step _step = _Step.request;
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Enter a valid email');
      return;
    }
    setState(() => _localError = null);
    await ref.read(authProvider.notifier).forgotPassword(email);
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.error) {
      setState(() => _localError = auth.error);
    } else {
      setState(() => _step = _Step.reset);
    }
  }

  Future<void> _reset() async {
    if (_otp.text.trim().isEmpty) {
      setState(() => _localError = 'Enter the code');
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _localError = 'Password must be at least 8 characters');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _localError = 'Passwords do not match');
      return;
    }
    setState(() => _localError = null);
    await ref.read(authProvider.notifier).resetPassword(
          email: _email.text.trim(),
          token: _otp.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.error) {
      setState(() => _localError = auth.error);
    } else if (auth.status == AuthStatus.authenticated) {
      setState(() => _step = _Step.done);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) context.go(ref.read(roleConfigProvider).homeRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final loading = auth.status == AuthStatus.loading;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Reset Password', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _step == _Step.request
                    ? 'Forgot your password?'
                    : 'Enter the code we sent',
                style: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                _step == _Step.request
                    ? 'We\'ll email you a code to reset it.'
                    : 'Check ${_email.text.trim()} for the reset code.',
                style: GoogleFonts.inter(
                    fontSize: 13.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),
              SportXCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_step == _Step.request)
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(LucideIcons.mail, size: 18),
                        ),
                      )
                    else ...[
                      TextField(
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Reset code',
                          prefixIcon: Icon(LucideIcons.shieldCheck, size: 18),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New password',
                          prefixIcon: Icon(LucideIcons.lock, size: 18),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _confirm,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(LucideIcons.lock, size: 18),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_localError != null) ...[
                const SizedBox(height: 12),
                Text(_localError!,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.error)),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: _step == _Step.request
                      ? 'Send reset code'
                      : 'Reset password',
                  icon: LucideIcons.arrowRight,
                  onPressed: loading
                      ? null
                      : (_step == _Step.request ? _request : _reset),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text('Back to log in',
                      style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDarker)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
