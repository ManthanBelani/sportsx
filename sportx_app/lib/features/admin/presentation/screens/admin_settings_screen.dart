import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// v2 admin-settings.html — System Settings.
/// Local draft state (no platform-settings endpoint exists yet):
/// toggling updates the draft; Save confirms. Sections mirror the
/// web panel's settings/system-settings pages.
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _maintenance = false;
  bool _trialRegsOpen = true;
  bool _tournamentRegsOpen = true;
  bool _autoApproveTrials = false;
  bool _autoApproveTournaments = false;
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _reportAlerts = true;
  bool _dirty = false;

  void _set(void Function() fn) => setState(() {
        fn();
        _dirty = true;
      });

  void _save() {
    setState(() => _dirty = false);
    SnackBarUtils.showSuccess(context, 'Settings saved');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.ink),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/admin/dashboard'),
        ),
        title: Text('System Settings',
            style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          _section('General', LucideIcons.settings, [
            _toggle('Maintenance mode', 'Take the app offline for users',
                _maintenance, (v) => _set(() => _maintenance = v),
                danger: true),
            _toggle('Trial registrations', 'Allow new trial entries',
                _trialRegsOpen, (v) => _set(() => _trialRegsOpen = v)),
            _toggle(
                'Tournament registrations',
                'Allow new tournament entries',
                _tournamentRegsOpen,
                (v) => _set(() => _tournamentRegsOpen = v)),
          ]),
          _section('Content Approvals', LucideIcons.shieldCheck, [
            _toggle('Auto-approve trials', 'Skip manual trial review',
                _autoApproveTrials, (v) => _set(() => _autoApproveTrials = v)),
            _toggle(
                'Auto-approve tournaments',
                'Skip manual tournament review',
                _autoApproveTournaments,
                (v) => _set(() => _autoApproveTournaments = v)),
          ]),
          _section('Notifications', LucideIcons.bell, [
            _toggle('Push notifications', 'Send pushes to users',
                _pushEnabled, (v) => _set(() => _pushEnabled = v)),
            _toggle('Email notifications', 'Send emails to users',
                _emailEnabled, (v) => _set(() => _emailEnabled = v)),
            _toggle('Moderation alerts', 'Alert admins on new reports',
                _reportAlerts, (v) => _set(() => _reportAlerts = v)),
          ]),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: PrimaryButton(
                label: _dirty ? 'Save Changes' : 'Saved',
                onPressed: _dirty ? _save : null),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.yellowDeep),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: SportXShadows.e1,
            ),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged,
      {bool danger = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: danger && value
                            ? AppColors.error
                            : AppColors.ink)),
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
            activeThumbColor: AppColors.yellowDeep,
            activeTrackColor: AppColors.yellowTint,
          ),
        ],
      ),
    );
  }
}
