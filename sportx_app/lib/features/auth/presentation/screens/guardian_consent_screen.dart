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
  final _phone = TextEditingController();
  final _otp = TextEditingController();

  bool _otpSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
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
    final phone = _phone.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      SnackBarUtils.showError(context, 'Please enter guardian name and phone');
      return;
    }

    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/guardian/consent', data: {
        'guardian_name': name,
        'guardian_phone': phone,
        'relationship': 'parent',
      });

      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _loading = false;
      });
      SnackBarUtils.showSuccess(context, 'OTP sent to guardian. Please enter the code.');
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

      // Navigate to next onboarding step or home
      final role = sportXRoleFromId(ref.read(authProvider).user?.role) ??
          SportXRole.athlete;
      final next = roleConfigFor(role).onboardingRoute;
      if (next != null) {
        context.go(next);
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
      onSubmit: _loading ? null : _submit,
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
                  ? 'Enter the OTP sent to the guardian\'s phone to verify consent.'
                  : 'A guardian must verify consent before a minor can register for '
                      'events, opportunities or connect with others.',
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
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Guardian phone',
              prefixIcon: Icon(LucideIcons.phone, size: 18),
            ),
          ),
        ] else ...[
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'OTP sent to guardian',
              prefixIcon: Icon(LucideIcons.shieldCheck, size: 18),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          _otpSent
              ? 'Enter the 6-digit code sent via SMS to verify guardian consent.'
              : 'The guardian will receive an SMS to confirm consent.',
          style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
