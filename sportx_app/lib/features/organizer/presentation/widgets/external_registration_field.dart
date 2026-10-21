import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';

/// Validates an optional external registration URL.
///
/// Returns `null` when the value is acceptable (an empty value is allowed —
/// the field is optional) or a human readable error message.
String? validateExternalRegistrationUrl(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    return 'Enter a full link, e.g. https://forms.example.com/my-cup';
  }
  if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
    return 'The link must start with http:// or https://';
  }
  return null;
}

/// Optional "External Registration URL" input used by the tournament create
/// and edit forms.
///
/// When a link is set, the tournament's Register button sends the user to
/// that page instead of the in-app registration flow, and SportX only counts
/// the clicks (the external site owns the actual sign-up).
class ExternalRegistrationUrlField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<bool>? onEnabledChanged;
  final String? errorText;

  const ExternalRegistrationUrlField({
    super.key,
    required this.controller,
    required this.enabled,
    this.onEnabledChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? AppColors.primary.withValues(alpha: 0.45) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                enabled ? LucideIcons.link : LucideIcons.link2,
                size: 18,
                color: enabled ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use my own registration page',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled
                          ? 'The Register button will open your link.'
                          : 'Leave off to use SportX registration.',
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => onEnabledChanged?.call(v),
              ),
            ],
          ),
        ),
        if (enabled) ...[
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'External Registration URL',
              hintText: 'https://forms.example.com/my-cup',
              errorText: errorText,
              prefixIcon: const Icon(LucideIcons.globe, size: 18),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Athletes will be taken to this page to register. We only count the clicks — '
            'registrations completed there are not visible on SportX.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
