import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';

class RegistrationConfirmationScreen extends StatelessWidget {
  final String? registrationRef;
  final String? eventName;
  final String? eventDate;
  final String? eventTime;
  final String? venue;
  final bool isTrial;

  const RegistrationConfirmationScreen({
    super.key,
    this.registrationRef,
    this.eventName,
    this.eventDate,
    this.eventTime,
    this.venue,
    this.isTrial = true,
  });

  @override
  Widget build(BuildContext context) {
    final title = isTrial ? 'You have successfully registered for the trial.' : 'You have successfully registered for the tournament.';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFd1fae5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.checkCircle, size: 40, color: Color(0xFF059669)),
              ),
              const SizedBox(height: 24),

              const Text('Registration Confirmed!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (eventDate != null) ...[
                      _buildDetailRow(LucideIcons.calendar, 'Date', eventDate!),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: AppColors.border, height: 1)),
                    ],
                    if (eventTime != null) ...[
                      _buildDetailRow(LucideIcons.clock, 'Time', eventTime!),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: AppColors.border, height: 1)),
                    ],
                    if (venue != null) _buildDetailRow(LucideIcons.mapPin, 'Location', venue!),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (registrationRef != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFe6f0ff),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.hash, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(registrationRef!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ),

              const Spacer(),

              ElevatedButton(
                onPressed: () => context.go('/activity-hub'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('View in Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
