import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class TrialRegistrationScreen extends ConsumerStatefulWidget {
  final String trialId;
  const TrialRegistrationScreen({super.key, required this.trialId});

  @override
  ConsumerState<TrialRegistrationScreen> createState() => _TrialRegistrationScreenState();
}

class _TrialRegistrationScreenState extends ConsumerState<TrialRegistrationScreen> {
  bool _parentalConsent = false;
  bool _submitting = false;
  final _roleController = TextEditingController();
  final _medicalController = TextEditingController();

  @override
  void dispose() {
    _roleController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(dioProvider).post('/trials/${widget.trialId}/register', data: {
        'playing_role': _roleController.text.trim(),
        'medical_conditions': _medicalController.text.trim(),
        'parental_consent': _parentalConsent,
      });
      if (mounted) context.push('/registration-confirmation');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.user, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Athlete', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        const Text('Athlete', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Details Required
            Row(
              children: [
                const Icon(LucideIcons.fileText, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Details Required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildLabel('Playing Role / Speciality'),
            _buildTextField('e.g., Right-arm Fast Bowler', controller: _roleController),

            const SizedBox(height: 16),
            _buildLabel('Medical Conditions (if any)'),
            _buildTextField('e.g., Asthma, Allergies, or None', controller: _medicalController),
            
            const SizedBox(height: 16),
            _buildLabel('ID Proof (Aadhaar / Passport)'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.upload, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text('Upload File', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _parentalConsent,
                  onChanged: (v) => setState(() => _parentalConsent = v ?? false),
                  activeColor: AppColors.primary,
                ),
                const Expanded(child: Text('I have parental consent for this trial.', style: TextStyle(fontSize: 13, color: AppColors.textPrimary))),
              ],
            ),

            const SizedBox(height: 24),

            // Payment Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Registration Fee', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const Text('₹200', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Platform Fee', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const Text('₹50', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const Text('₹250', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (_parentalConsent && !_submitting) ? _submit : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                disabledBackgroundColor: AppColors.border,
              ),
              child: _submitting
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Pay ₹250 & Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
    );
  }

  Widget _buildTextField(String hint, {TextEditingController? controller}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
