import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:dio/dio.dart';

/// AT.10 Guardian / Parent Controls — parent manages a minor's account.
class GuardianControlsScreen extends ConsumerStatefulWidget {
  const GuardianControlsScreen({super.key});

  @override
  ConsumerState<GuardianControlsScreen> createState() =>
      _GuardianControlsScreenState();
}

class _GuardianControlsScreenState
    extends ConsumerState<GuardianControlsScreen> {
  bool _restrictMessaging = true;
  bool _restrictVisibility = true;
  bool _postApproval = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadControls();
  }

  Future<void> _loadControls() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/me/guardian-controls');
      final data = resp.data['data'] as Map<String, dynamic>?;

      if (!mounted) return;
      setState(() {
        // allow_messages = true means messaging is ALLOWED (not restricted)
        // So restrictMessaging = !allow_messages
        _restrictMessaging = !(data?['allow_messages'] ?? false);
        _restrictVisibility = !(data?['allow_public_profile'] ?? false);
        // leaderboard_name_mode: 'first_name_initial' or 'hidden' = restricted
        // 'full_name' = not restricted
        _postApproval = data?['leaderboard_name_mode'] != 'full_name';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      SnackBarUtils.showError(context, 'Failed to load guardian controls');
    }
  }

  Future<void> _saveControls() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/me/guardian-controls', data: {
        'allow_messages': !_restrictMessaging,
        'allow_public_profile': !_restrictVisibility,
        'leaderboard_name_mode': _postApproval ? 'first_name_initial' : 'full_name',
      });

      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Guardian controls updated');
    } on DioException catch (e) {
      if (!mounted) return;
      final apiEx = ApiException.fromDio(e);
      SnackBarUtils.showError(context, apiEx.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Guardian Controls', showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                            Text('Guardian consent verified',
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
                  subtitle: 'Only approved connections can message this account',
                  value: _restrictMessaging,
                  onChanged: (v) {
                    setState(() => _restrictMessaging = v);
                    _saveControls();
                  },
                ),
                _toggle(
                  icon: LucideIcons.eyeOff,
                  title: 'Limit profile visibility',
                  subtitle: 'Hide profile from non-verified accounts',
                  value: _restrictVisibility,
                  onChanged: (v) {
                    setState(() => _restrictVisibility = v);
                    _saveControls();
                  },
                ),
                _toggle(
                  icon: LucideIcons.clipboardCheck,
                  title: 'Approve posts before publishing',
                  subtitle: 'Review every post this account shares',
                  value: _postApproval,
                  onChanged: (v) {
                    setState(() => _postApproval = v);
                    _saveControls();
                  },
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
                          'Changes are saved automatically and enforced immediately.',
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
            onChanged: _saving ? null : onChanged,
            activeThumbColor: AppColors.ink,
          ),
        ],
      ),
    );
  }
}