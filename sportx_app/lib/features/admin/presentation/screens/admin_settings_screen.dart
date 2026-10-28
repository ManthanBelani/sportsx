import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Photo-limit numeric keys (value is a TextEditController per key).
  final Map<String, TextEditingController> _numeric = {};

  static const _photoLimitRows = [
    ('gallery_photo_limit_athlete', 'Athlete'),
    ('gallery_photo_limit_coach', 'Coach'),
    ('gallery_photo_limit_academy', 'Academy'),
    ('gallery_photo_limit_organizer', 'Organizer'),
    ('gallery_photo_limit_talent_scout', 'Talent Scout'),
    ('gallery_photo_limit_sponsor', 'Sponsor'),
    ('post_max_photos', 'Photos per post'),
    ('photo_max_dimension', 'Max photo dimension (px)'),
    ('photo_jpeg_quality', 'Photo JPEG quality'),
  ];

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
      for (final r in _photoLimitRows) {
        final key = r.$1;
        _numeric[key] ??= TextEditingController();
        _numeric[key]!.text = ((raw[key] as num?) ?? 0).toString();
      }
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
          .put('/admin/settings', data: {
        ..._values,
        // Numeric photo limits: parse ints, fall back to the current value on
        // garbage input so a stray character never wipes a setting.
        for (final r in _photoLimitRows)
          r.$1: int.tryParse(_numeric[r.$1]!.text.trim()) ?? 0,
      });
      final raw = Map<String, dynamic>.from(
        resp.data['data']['settings'] as Map,
      );
      if (!mounted) return;
      final values = {
        for (final r in _rows) r.$1: (raw[r.$1] as bool?) ?? false,
      };
      for (final r in _photoLimitRows) {
        final key = r.$1;
        _numeric[key] ??= TextEditingController();
        _numeric[key]!.text = ((raw[key] as num?) ?? 0).toString();
      }
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
                _photoLimitsSection(),
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

  /// Photo limits — per-role gallery photo caps plus compression knobs.
  /// Only `gallery` photos count against a role's limit.
  Widget _photoLimitsSection() {
    return _section('Photo Limits', LucideIcons.images, [
      for (final r in _photoLimitRows) _numericField(r.$1, r.$2),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Text(
          'Gallery photos count against a role\'s limit. Profile, cover, logo, post, achievement and document photos are always free. 0 disables gallery uploads for that role.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ]);
  }

  Widget _numericField(String key, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: TextField(
              controller: _numeric[key],
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,5}$')),
              ],
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
        ],
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
