import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/role_config.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/form_page_template.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:dio/dio.dart';

/// A.9 Guardian Consent — required when an athlete is under 18.
class GuardianConsentScreen extends ConsumerStatefulWidget {
  const GuardianConsentScreen({super.key});

  @override
  ConsumerState<GuardianConsentScreen> createState() =>
      _GuardianConsentScreenState();
}

class _GuardianConsentScreenState
    extends ConsumerState<GuardianConsentScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();

  bool _otpSent = false;
  bool _loading = false;
  bool _resending = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;

    if (!_otpSent) {
      // Step 1: Request consent (send OTP to guardian)
      await _requestConsent();
    } else {
      // Step 2: Verify OTP
      await _verifyOtp();
    }
  }

  Future<void> _requestConsent() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();

    if (name.isEmpty || email.isEmpty) {
      SnackBarUtils.showError(context, 'Please enter guardian name and email');
      return;
    }

    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/guardian/consent', data: {
        'guardian_name': name,
        'guardian_email': email,
        if (phone.isNotEmpty) 'guardian_phone': phone,
        'relationship': 'parent',
      });

      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _loading = false;
      });
      SnackBarUtils.showSuccess(
          context, 'Code emailed to your guardian. Ask them to enter it here.');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final apiEx = ApiException.fromDio(e);
      if (apiEx.fieldErrors.isNotEmpty) {
        SnackBarUtils.showValidationError(context, apiEx.fieldErrors, apiEx);
      } else {
        SnackBarUtils.showError(context, apiEx);
      }
    }
  }

  Future<void> _resendEmail() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/guardian/resend');
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Confirmation email re-sent to your guardian.');
    } on DioException catch (e) {
      if (!mounted) return;
      final apiEx = ApiException.fromDio(e);
      SnackBarUtils.showError(context, apiEx);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otp.text.trim();

    if (otp.isEmpty) {
      SnackBarUtils.showError(context, 'Please enter the OTP');
      return;
    }

    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/guardian/verify-otp', data: {'code': otp});

      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Guardian consent verified successfully!');

      // Navigate to next onboarding step or home/previous screen
      final authState = ref.read(authProvider);
      if (authState.needsOnboarding) {
        final role = sportXRoleFromId(authState.user?.role) ?? SportXRole.athlete;
        final next = roleConfigFor(role).onboardingRoute;
        if (next != null) {
          context.go(next);
          return;
        }
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final apiEx = ApiException.fromDio(e);
      if (apiEx.fieldErrors.isNotEmpty) {
        SnackBarUtils.showValidationError(context, apiEx.fieldErrors, apiEx);
      } else {
        SnackBarUtils.showError(context, apiEx);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageTemplate(
      title: 'Guardian Consent',
      ctaText: _otpSent ? 'Verify consent' : 'Send consent request',
      confirmText:
          'I am the parent or legal guardian of this athlete and I consent to '
          'their participation on SportX.',
      onSubmit: _submit,
      autoFilledProfile: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.yellowTint,
            ),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.shieldCheck,
                size: 20, color: AppColors.warnText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _otpSent
                  ? 'Ask your parent or guardian to open their email and enter '
                      'the 6-digit code here. Hand the phone to them.'
                  : 'A parent or guardian must verify consent before a minor can '
                      'chat, register for events or connect with others.',
              style: GoogleFonts.inter(
                  fontSize: 12.5, height: 1.45, color: AppColors.dark),
            ),
          ),
        ],
      ),
      formFields: [
        if (!_otpSent) ...[
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Guardian full name',
              prefixIcon: Icon(LucideIcons.user, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Guardian email',
              helperText:
                  'We email your parent or guardian a permission code here',
              prefixIcon: Icon(LucideIcons.mail, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Guardian phone (optional)',
              prefixIcon: Icon(LucideIcons.phone, size: 18),
            ),
          ),
        ] else ...[
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Code sent to guardian\'s email',
              prefixIcon: Icon(LucideIcons.shieldCheck, size: 18),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (!_otpSent)
          Text(
            'Your parent or guardian will receive an email with a 6-digit code. '
            'They enter it on this screen to approve your account.',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary),
          )
        else
          TextButton.icon(
            onPressed: _resending ? null : _resendEmail,
            icon: _resending
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.mail, size: 16),
            label: Text(
              'Resend email to guardian',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
