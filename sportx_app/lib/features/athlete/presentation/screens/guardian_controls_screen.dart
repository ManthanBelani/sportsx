import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// AT.10 Guardian / Parent Controls — parent manages a minor's account.
class GuardianControlsScreen extends StatefulWidget {
  const GuardianControlsScreen({super.key});

  @override
  State<GuardianControlsScreen> createState() => _GuardianControlsScreenState();
}

class _GuardianControlsScreenState extends State<GuardianControlsScreen> {
  bool _restrictMessaging = true;
  bool _restrictVisibility = true;
  bool _postApproval = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Guardian Controls', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SportXCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.shieldCheck,
                      size: 22, color: AppColors.info),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Consent status',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                      const SizedBox(height: 2),
                      Text('Guardian consent recorded',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const StatusPill(label: 'ACTIVE', kind: PillKind.ok),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Privacy & safety',
              style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 12),
          _toggle(
            icon: LucideIcons.messageCircle,
            title: 'Restrict messages',
            subtitle: 'Only people you approve can message',
            value: _restrictMessaging,
            onChanged: (v) => setState(() => _restrictMessaging = v),
          ),
          _toggle(
            icon: LucideIcons.eyeOff,
            title: 'Limit profile visibility',
            subtitle: 'Hide from non-verified accounts',
            value: _restrictVisibility,
            onChanged: (v) => setState(() => _restrictVisibility = v),
          ),
          _toggle(
            icon: LucideIcons.clipboardCheck,
            title: 'Approve posts before publishing',
            subtitle: 'Review every post this account shares',
            value: _postApproval,
            onChanged: (v) => setState(() => _postApproval = v),
          ),
          const SizedBox(height: 18),
          SportXCard(
            child: Row(
              children: [
                const Icon(LucideIcons.info,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These controls apply until the account holder turns 18. '
                    'You can update them anytime.',
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SportXCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.ink,
          ),
        ],
      ),
    );
  }
}
