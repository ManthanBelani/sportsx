import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/shared/providers/profile_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// One sport the athlete plays, resolved from the `athlete_sports` pivot.
class SportEntry {
  final int sportId;
  final String sport;
  final String role;
  final String level;
  final int experienceYears;
  final bool primary;

  const SportEntry({
    required this.sportId,
    required this.sport,
    this.role = '',
    this.level = '',
    this.experienceYears = 0,
    this.primary = false,
  });

  factory SportEntry.fromPivot(Map<String, dynamic> json) {
    final pivot = (json['pivot'] as Map?)?.cast<String, dynamic>() ?? const {};
    return SportEntry(
      sportId: (json['id'] as num?)?.toInt() ?? 0,
      sport: (json['name'] ?? '').toString(),
      role: (pivot['playing_role'] ?? '').toString(),
      level: (pivot['level'] ?? '').toString(),
      experienceYears: (pivot['experience_years'] as num?)?.toInt() ?? 0,
      primary: pivot['is_primary'] == true || pivot['is_primary'] == 1,
    );
  }

  SportEntry copyWith({
    String? role,
    String? level,
    int? experienceYears,
    bool? primary,
  }) {
    return SportEntry(
      sportId: sportId,
      sport: sport,
      role: role ?? this.role,
      level: level ?? this.level,
      experienceYears: experienceYears ?? this.experienceYears,
      primary: primary ?? this.primary,
    );
  }

  /// Rich shape accepted by `PUT /me/profile/sports`.
  Map<String, dynamic> toApi() => {
    'sport_id': sportId,
    'playing_role': role.isEmpty ? null : role,
    'level': level.isEmpty ? null : level,
    'experience_years': experienceYears,
    'is_primary': primary,
  };
}

/// AT.4 Manage Sports — multi-sport profile data, fully wired to
/// `GET /me/profile` (athlete `sports` pivot) and `PUT /me/profile/sports`.
class ManageSportsScreen extends ConsumerStatefulWidget {
  const ManageSportsScreen({super.key});

  @override
  ConsumerState<ManageSportsScreen> createState() => _ManageSportsScreenState();
}

class _ManageSportsScreenState extends ConsumerState<ManageSportsScreen> {
  List<SportEntry>? _sports;
  bool _saving = false;

  /// Seed the local list from the profile once it arrives.
  void _syncFromProfile(Map<String, dynamic>? profile) {
    if (_sports != null || profile == null) return;
    final sports = profile['sports'];
    if (sports is! List) return;
    _sports = [
      for (final s in sports)
        if (s is Map) SportEntry.fromPivot(s.cast<String, dynamic>()),
    ];
    // Guarantee a primary exists so the profile leads with one sport.
    if (_sports!.isNotEmpty && !_sports!.any((s) => s.primary)) {
      _sports![0] = _sports![0].copyWith(primary: true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _setPrimary(int index) {
    setState(() {
      for (var i = 0; i < _sports!.length; i++) {
        _sports![i] = _sports![i].copyWith(primary: i == index);
      }
    });
  }

  /// Persists the whole list — the endpoint syncs the pivot in one call.
  Future<void> _save() async {
    final sports = _sports ?? const <SportEntry>[];
    if (sports.isEmpty) {
      SnackBarUtils.showError(context, 'Add at least one sport.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(dioProvider)
          .put(
            '/me/profile/sports',
            data: {
              'sports': [for (final s in sports) s.toApi()],
            },
          );
      ref.invalidate(profileProvider);
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Sports updated');
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) SnackBarUtils.showError(context, ApiException.fromDio(e));
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e, 'Could not save your sports.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addSport() async {
    final existingIds = {
      for (final s in _sports ?? const <SportEntry>[]) s.sportId,
    };
    final added = await showModalBottomSheet<SportEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSportSheet(takenIds: existingIds),
    );
    if (added != null) setState(() => (_sports ??= []).add(added));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    // First load — profile may be null while fetching or for non-athletes.
    if (_sports == null) {
      _syncFromProfile(profileAsync.valueOrNull);
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SportXTopBar(
        title: 'Manage Sports',
        showBack: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
          ),
        ],
      ),
      body: profileAsync.isLoading && _sports == null
          ? const GenericListSkeleton()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Text(
                  'Add every sport you play. Mark one as primary — it leads your profile.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                if (_sports == null || _sports!.isEmpty)
                  EmptyState(
                    icon: LucideIcons.dumbbell,
                    title: 'No sports added yet',
                    message:
                        'Add the sports you play to complete your profile.',
                  )
                else ...[
                  for (var i = 0; i < _sports!.length; i++) _card(i),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SecondaryButton(
                    label: 'Add another sport',
                    icon: LucideIcons.plus,
                    onPressed: _addSport,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _card(int index) {
    final s = _sports![index];
    final meta = [
      if (s.role.isNotEmpty) s.role,
      if (s.level.isNotEmpty) s.level,
      if (s.experienceYears > 0) '${s.experienceYears} yrs',
    ].join(' · ');
    return SportXCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.yellowTint,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.dumbbell,
                  size: 20,
                  color: AppColors.warnText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.sport,
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.isEmpty ? 'No details added' : meta,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (s.primary)
                const StatusPill(label: 'PRIMARY', kind: PillKind.feat),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!s.primary)
                Expanded(
                  child: SecondaryButton(
                    label: 'Set primary',
                    icon: LucideIcons.star,
                    onPressed: () => _setPrimary(index),
                  ),
                ),
              if (!s.primary) const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  label: 'Remove',
                  icon: LucideIcons.trash2,
                  onPressed: () => setState(() => _sports!.removeAt(index)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddSportSheet extends ConsumerStatefulWidget {
  /// Sport ids already on the profile — excluded from the picker.
  final Set<int> takenIds;
  const _AddSportSheet({required this.takenIds});

  @override
  ConsumerState<_AddSportSheet> createState() => _AddSportSheetState();
}

class _AddSportSheetState extends ConsumerState<_AddSportSheet> {
  final _role = TextEditingController();
  final _experience = TextEditingController();
  int? _sportId;
  String _level = 'District';
  bool _submitting = false;

  static const _levels = [
    'School',
    'District',
    'State',
    'National',
    'International',
  ];

  @override
  void dispose() {
    _role.dispose();
    _experience.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sportId == null) return;
    setState(() => _submitting = true);
    // Validate the sport id against the master list, then hand the entry back.
    final sports = ref.read(metaProvider).sports;
    final sport = sports.firstWhere(
      (s) => s.id == _sportId,
      orElse: () => sports.first,
    );
    final years =
        int.tryParse(
          _experience.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    Navigator.of(context).pop(
      SportEntry(
        sportId: _sportId!,
        sport: sport.name,
        role: _role.text.trim(),
        level: _level,
        experienceYears: years,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
    final available = meta.sports
        .where((s) => s.isActive && !widget.takenIds.contains(s.id))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a sport',
              style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            meta.isLoading && available.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : DropdownButtonFormField<int>(
                    initialValue: _sportId,
                    decoration: const InputDecoration(labelText: 'Sport'),
                    items: [
                      for (final s in available)
                        DropdownMenuItem(value: s.id, child: Text(s.name)),
                    ],
                    onChanged: (v) => setState(() => _sportId = v),
                  ),
            const SizedBox(height: 12),
            TextField(
              controller: _role,
              decoration: const InputDecoration(
                labelText: 'Playing role / position',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Level'),
              items: _levels
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) => setState(() => _level = v ?? _level),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _experience,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Experience (years)',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: _submitting ? 'Adding…' : 'Add sport',
                icon: LucideIcons.check,
                onPressed: _submitting || _sportId == null ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
