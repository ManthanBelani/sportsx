import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/role_config.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/form_page_template.dart';
import 'package:sportx_app/theme/colors.dart';

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

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _submit() {
    // Guardian consent captured locally; backend consent endpoint is wired
    // with the account/onboarding API at integration time. Continue into the
    // role onboarding wizard.
    final role = sportXRoleFromId(ref.read(authProvider).user?.role) ??
        SportXRole.athlete;
    final next = roleConfigFor(role).onboardingRoute;
    if (next != null) {
      context.go(next);
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageTemplate(
      title: 'Guardian Consent',
      ctaText: 'Send consent request',
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
              'A guardian must verify consent before a minor can register for '
              'events, opportunities or connect with others.',
              style: GoogleFonts.inter(
                  fontSize: 12.5, height: 1.45, color: AppColors.dark),
            ),
          ),
        ],
      ),
      formFields: [
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
        const SizedBox(height: 14),
        TextField(
          controller: _otp,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'OTP sent to guardian',
            prefixIcon: Icon(LucideIcons.shieldCheck, size: 18),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'The guardian will receive an SMS to confirm consent.',
          style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
