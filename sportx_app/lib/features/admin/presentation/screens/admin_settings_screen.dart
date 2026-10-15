import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// v2 admin-settings.html — System Settings.
///
/// Backed by GET/PUT /admin/settings (platform_settings.json via
/// PlatformSettings). Every toggle here reads and writes the server — there
/// is no local-only draft state.
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, bool> _values = {};
  Map<String, bool> _initial = {};

  static const _rows = [
    (
      'maintenance_mode',
      'Maintenance mode',
      'Take the app offline for users',
      true,
    ),
    (
      'registrations_open',
      'Registrations open',
      'Allow new trial & event entries',
      false,
    ),
    (
      'auto_approve_trials',
      'Auto-approve trials',
      'Skip manual trial review',
      false,
    ),
    (
      'auto_approve_tournaments',
      'Auto-approve tournaments',
      'Skip manual tournament review',
      false,
    ),
    ('push_notifications', 'Push notifications', 'Send pushes to users', false),
    ('email_alerts', 'Email notifications', 'Send emails to users', false),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await ref.read(dioProvider).get('/admin/settings');
      final raw = Map<String, dynamic>.from(
        resp.data['data']['settings'] as Map,
      );
      final values = {
        for (final r in _rows) r.$1: (raw[r.$1] as bool?) ?? false,
      };
      if (mounted) {
        setState(() {
          _values = values;
          _initial = Map.of(values);
          _loading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              e.response?.data?['error']?['message']?.toString() ??
              'Could not load settings';
        });
      }
    }
  }

  bool get _dirty {
    if (_values.length != _initial.length) return false;
    for (final k in _values.keys) {
      if (_values[k] != _initial[k]) return true;
    }
    return false;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final resp = await ref
          .read(dioProvider)
          .put('/admin/settings', data: _values);
      final raw = Map<String, dynamic>.from(
        resp.data['data']['settings'] as Map,
      );
      if (!mounted) return;
      final values = {
        for (final r in _rows) r.$1: (raw[r.$1] as bool?) ?? false,
      };
      setState(() {
        _values = values;
        _initial = Map.of(values);
        _saving = false;
      });
      SnackBarUtils.showSuccess(context, 'Settings saved');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackBarUtils.showError(
        context,
        e.response?.data?['error']?['message']?.toString() ??
            'Could not save settings',
      );
    }
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
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin/dashboard'),
        ),
        title: Text(
          'System Settings',
          style: GoogleFonts.sora(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Retry', small: true, onPressed: _load),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
              children: [
                _section('General', LucideIcons.settings, [
                  _toggle(0, danger: true),
                  _toggle(1),
                ]),
                _section('Content Approvals', LucideIcons.shieldCheck, [
                  _toggle(2),
                  _toggle(3),
                ]),
                _section('Notifications', LucideIcons.bell, [
                  _toggle(4),
                  _toggle(5),
                ]),
              ],
            ),
      bottomSheet: _loading || _error != null
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                border: const Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: _saving
                        ? 'Saving…'
                        : (_dirty ? 'Save Changes' : 'Saved'),
                    onPressed: (_dirty && !_saving) ? _save : null,
                  ),
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
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
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

  Widget _toggle(int index, {bool danger = false}) {
    final row = _rows[index];
    final value = _values[row.$1] ?? false;
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
                Text(
                  row.$2,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: danger && value ? AppColors.error : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.$3,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) => setState(() => _values[row.$1] = v),
            activeThumbColor: AppColors.yellowDeep,
            activeTrackColor: AppColors.yellowTint,
          ),
        ],
      ),
    );
  }
}
