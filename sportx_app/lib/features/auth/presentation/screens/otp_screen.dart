import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  final String role;
  const OtpScreen({super.key, required this.email, required this.role});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_secondsLeft > 0) _secondsLeft--;
        });
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    await ref.read(authProvider.notifier).verifyOtp(email: widget.email, otp: _otp);
    final state = ref.read(authProvider);
    if (mounted) {
      if (state.status == AuthStatus.authenticated) {
        context.go('/home');
      } else if (state.status == AuthStatus.error) {
        SnackBarUtils.showError(context, state.error ?? 'Invalid OTP');
      }
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    await ref.read(authProvider.notifier).resendOtp(widget.email);
    if (mounted) {
      SnackBarUtils.showSuccess(context, 'OTP resent');
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).status == AuthStatus.loading;
    final canVerify = _otp.length == 6;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/role-selection');
            }
          },
        ),
        title: Text(
          'Verify Account',
          style: GoogleFonts.sora(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE9A8), Color(0xFFFFC107), Color(0xFFF5B400)],
                  ),
                  boxShadow: SportXShadows.btnShadow,
                ),
                child: const Icon(LucideIcons.mail, color: AppColors.ink, size: 30),
              ),
              const SizedBox(height: 24),
              Text(
                'Check your email',
                style: GoogleFonts.sora(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'We sent a verification code to\n',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: GoogleFonts.inter(color: AppColors.primaryDarker, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) => Padding(
                  padding: EdgeInsets.only(right: i < 5 ? 12 : 0),
                  child: SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus();
                        if (v.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
                        setState(() {});
                      },
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 24),

              Text.rich(
                TextSpan(
                  text: 'Resend code in ',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: '0:${_secondsLeft.toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (isLoading)
                Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFD54A), Color(0xFFFFC107), Color(0xFFF5B400)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x2E785000)),
                    boxShadow: SportXShadows.btnShadow,
                  ),
                  alignment: Alignment.center,
                  child: const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2)),
                )
              else
                Opacity(
                  opacity: canVerify ? 1.0 : 0.5,
                  child: PrimaryButton(
                    label: 'Verify & Continue',
                    icon: LucideIcons.shieldCheck,
                    onPressed: canVerify ? _verify : null,
                  ),
                ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: SportXShadows.e1,
                ),
                child: Text.rich(
                  TextSpan(
                    text: 'Didn\'t receive the code? Check your spam folder or ',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: _secondsLeft == 0 ? _resend : null,
                          child: Text(
                            'resend',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _secondsLeft == 0 ? AppColors.primaryDarker : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: ' after 0:${_secondsLeft.toString().padLeft(2, '0')}',
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
