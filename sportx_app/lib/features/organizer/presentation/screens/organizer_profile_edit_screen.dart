import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/media_picker.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/shared/providers/profile_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class OrganizerProfileEditScreen extends ConsumerStatefulWidget {
  const OrganizerProfileEditScreen({super.key});
  @override
  ConsumerState<OrganizerProfileEditScreen> createState() => _OrganizerProfileScreenState();
}

class _OrganizerProfileScreenState extends ConsumerState<OrganizerProfileEditScreen> {
  final _name = TextEditingController();
  final _regNo = TextEditingController();
  final _website = TextEditingController();
  final _desc = TextEditingController();
  String _type = 'federation';
  bool _saving = false;
  bool _loaded = false;
  int? _logoMediaId;
  int? _cityId;
  final Set<int> _sportIds = {};
  final Set<String> _eventTypes = {};
  bool _sportsEdited = false;

  final _typeOptions = const [
    {'value': 'federation', 'label': 'Federation / State Association'},
    {'value': 'club', 'label': 'Private Club'},
    {'value': 'other', 'label': 'Other'},
  ];

  // Spec §5 #5 — Event Types.
  static const _eventTypeOptions = [
    'tournament',
    'trial',
    'championship',
    'camp',
    'league',
    'workshop',
    'sports_meet',
    'marathon',
    'other',
  ];

  static String _eventTypeLabel(String v) {
    switch (v) {
      case 'tournament': return 'Tournament';
      case 'trial': return 'Trial';
      case 'championship': return 'Championship';
      case 'camp': return 'Camp';
      case 'league': return 'League';
      case 'workshop': return 'Workshop';
      case 'sports_meet': return 'Sports Meet';
      case 'marathon': return 'Marathon';
      default: return 'Other';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _regNo.dispose();
    _website.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _fillFromProfile(Map<String, dynamic> p) {
    if (_loaded) return;
    _name.text = (p['organization_name'] ?? '').toString();
    _regNo.text = (p['registration_number'] ?? '').toString();
    _website.text = (p['website'] ?? '').toString();
    final t = (p['org_type'] ?? 'federation').toString();
    if (_typeOptions.any((e) => e['value'] == t)) _type = t;
    _desc.text = (p['description'] ?? '').toString();
    final logo = (p['logo_media_id'] as num?)?.toInt();
    if (logo != null) _logoMediaId = logo;
    final city = (p['city_id'] as num?)?.toInt();
    if (city != null) _cityId = city;

    // Sports arrive as a list of ids under `sports`.
    _sportIds.clear();
    for (final s in (p['sports'] as List? ?? [])) {
      final id = (s is Map ? (s['id'] ?? s['sport_id']) : s) as num?;
      if (id != null) _sportIds.add(id.toInt());
    }

    // Event types arrive as a JSON array of strings.
    _eventTypes.clear();
    for (final e in (p['event_types'] as List? ?? [])) {
      final v = e.toString();
      if (_eventTypeOptions.contains(v)) _eventTypes.add(v);
    }
    _loaded = true;
  }

  Future<void> _pickLogo() async {
    final media = await pickAndUploadMedia(context, ref, mediaType: 'photo', uploadContext: 'logo');
    if (media == null || !mounted) return;
    setState(() => _logoMediaId = media.mediaId);
    if (mounted) SnackBarUtils.showSuccess(context, 'Logo updated — tap Save');
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Organization name required');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).put('/me/organizer', data: {
        'organization_name': _name.text.trim(),
        'org_type': _type,
        if (_regNo.text.trim().isNotEmpty) 'registration_number': _regNo.text.trim(),
        if (_website.text.trim().isNotEmpty) 'website': _website.text.trim(),
        if (_desc.text.trim().isNotEmpty) 'description': _desc.text.trim(),
        if (_logoMediaId != null) 'logo_media_id': _logoMediaId,
        if (_cityId != null) 'city_id': _cityId,
        if (_eventTypes.isNotEmpty) 'event_types': _eventTypes.toList(),
        // Sports only sent when the user changed them, to avoid clobbering
        // server-side entries on an unconditional save.
        if (_sportsEdited) 'sports': _sportIds.toList(),
      });
      ref.invalidate(myOrganizerProvider);
      // The home greet card shows the completion %, and the More header
      // renders the profile — keep both in sync with the edit.
      ref.invalidate(organizerCompletionProvider);
      ref.invalidate(profileProvider);
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Organization updated');
        context.pop();
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myOrganizerProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Edit Profile', style: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: AppColors.border)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDarker))
                  : PrimaryButton(small: true, label: 'Save', icon: LucideIcons.check, onPressed: _save),
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const GenericListSkeleton(),
        error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(ApiException.messageFor(e)), const SizedBox(height: 12), SecondaryButton(label: 'Retry', onPressed: () => ref.invalidate(myOrganizerProvider))])),
        data: (profile) {
          _fillFromProfile(profile);
          final meta = ref.watch(metaProvider);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Organization Name *'),
              TextField(controller: _name, decoration: const InputDecoration(hintText: 'Karnataka State Football Association')),
              const SizedBox(height: 16),
              _label('Organization Type'),
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: _typeOptions.map((o) => DropdownMenuItem(value: o['value']!, child: Text(o['label']!, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 16),
              _label('Registration Number'),
              TextField(controller: _regNo, decoration: const InputDecoration(hintText: 'REG/2020/0456')),
              const SizedBox(height: 16),
              _label('Website'),
              TextField(controller: _website, decoration: const InputDecoration(hintText: 'https://')),
              const SizedBox(height: 16),

              // ── Spec §5 mandatory fields that had no UI ──────────────────────
              _label('Logo'),
              _LogoTile(mediaId: _logoMediaId, onTap: _pickLogo),
              const SizedBox(height: 16),

              _label('Primary Sport'),
              _MultiChipPicker(
                all: meta.sports.where((s) => s.isActive).map((s) => {'id': s.id, 'name': s.name}).toList(),
                selected: _sportIds,
                labelOf: (s) => (s['name'] ?? '').toString(),
                onChanged: () => _sportsEdited = true,
              ),
              const SizedBox(height: 16),

              _label('City'),
              _CityDropdown(value: _cityId, onChanged: (v) => setState(() => _cityId = v)),
              const SizedBox(height: 16),

              _label('Event Types'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _eventTypeOptions.map((e) {
                  final selected = _eventTypes.contains(e);
                  return FilterChip(
                    label: Text(_eventTypeLabel(e)),
                    selected: selected,
                    showCheckmark: false,
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.yellowTint,
                    side: BorderSide(color: selected ? AppColors.yellowDeep : AppColors.border),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: selected ? AppColors.primaryDarker : AppColors.textSecondary,
                    ),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _eventTypes.add(e);
                      } else {
                        _eventTypes.remove(e);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _label('Short Description'),
              TextField(
                controller: _desc,
                maxLines: 4,
                decoration: const InputDecoration(hintText: '2–3 lines about your organization'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(children: [Icon(LucideIcons.info, size: 16, color: AppColors.info), SizedBox(width: 8), Expanded(child: Text('Verification documents are managed via onboarding. Contact support to update them.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.info)))]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  label: 'Manage Social Links',
                  icon: LucideIcons.share2,
                  onPressed: () => context.push('/social-links'),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)));
}

/// Spec §5 #2 — Logo upload.
class _LogoTile extends StatelessWidget {
  final int? mediaId;
  final VoidCallback onTap;
  const _LogoTile({required this.mediaId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: mediaId != null ? AppColors.success : AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            mediaId != null ? LucideIcons.checkCircle : LucideIcons.imagePlus,
            size: 24,
            color: mediaId != null ? AppColors.success : AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text(
            mediaId != null ? 'Logo uploaded — tap to change' : 'Upload logo',
            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ]),
      ),
    );
  }
}

/// Spec §5 #4 — Primary Sport, multi-select chips.
class _MultiChipPicker extends StatelessWidget {
  final List<Map<String, dynamic>> all;
  final Set<int> selected;
  final String Function(Map<String, dynamic>) labelOf;
  final VoidCallback onChanged;

  const _MultiChipPicker({
    required this.all,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (all.isEmpty) {
      return Text('No sports available', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: all.map((s) {
        final id = (s['id'] as num).toInt();
        final isOn = selected.contains(id);
        return FilterChip(
          label: Text(labelOf(s)),
          selected: isOn,
          showCheckmark: false,
          backgroundColor: Colors.white,
          selectedColor: AppColors.yellowTint,
          side: BorderSide(color: isOn ? AppColors.yellowDeep : AppColors.border),
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            color: isOn ? AppColors.primaryDarker : AppColors.textSecondary,
          ),
          onSelected: (v) {
            if (v) { selected.add(id); } else { selected.remove(id); }
            onChanged();
          },
        );
      }).toList(),
    );
  }
}

/// Spec §5 #6 — City / State.
class _CityDropdown extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  const _CityDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final meta = ref.watch(metaProvider);
      if (meta.isLoading) {
        return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
      }
      final cities = meta.cities.where((c) => c.isActive).toList();
      return DropdownButtonFormField<int?>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(hintText: 'Select city'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Not set')),
          ...cities.map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.state.isEmpty ? c.name : '${c.name}, ${c.state}'),
              )),
        ],
        onChanged: onChanged,
      );
    });
  }
}
