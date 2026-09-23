import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tfaController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tfaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    final notifier = ref.read(adminProvider.notifier);
    final ok = await notifier.login(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;
    if (ok && _tfaController.text.trim().isNotEmpty) {
      await notifier.verify2fa(_tfaController.text.trim());
    }
    setState(() => _loading = false);
    if (!mounted) return;
    final state = ref.read(adminProvider);
    if (state.isLoggedIn) {
      context.go('/admin/dashboard');
    } else {
      SnackBarUtils.showError(context, state.error ?? 'Login failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE9A8), Color(0xFFFFC107), Color(0xFFF5B400)],
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.shieldCheck, size: 40, color: AppColors.ink),
              ),
              const SizedBox(height: 20),
              Text('Admin Portal',
                  style: GoogleFonts.sora(
                      fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 8),
              Text('SportX India Platform Management',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13.5)),
              const SizedBox(height: 12),
              const StatusPill(label: 'MODERATION ACCESS', kind: PillKind.no),
              const SizedBox(height: 36),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(LucideIcons.mail, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(LucideIcons.lock, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        color: AppColors.textSecondary),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tfaController,
                decoration: InputDecoration(
                  labelText: '2FA Code',
                  prefixIcon: const Icon(LucideIcons.shieldCheck, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 24),
              if (_loading)
                const SizedBox(
                    height: 48,
                    width: 48,
                    child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.ctaDark))
              else
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                      label: 'Log In', icon: LucideIcons.logIn, onPressed: _login),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
