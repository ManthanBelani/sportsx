import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class SportEntry {
  final String sport;
  final String role; // playing role / position
  final String level;
  final String experience;
  final bool primary;

  const SportEntry({
    required this.sport,
    required this.role,
    required this.level,
    required this.experience,
    this.primary = false,
  });

  SportEntry copyWith({bool? primary}) => SportEntry(
        sport: sport,
        role: role,
        level: level,
        experience: experience,
        primary: primary ?? this.primary,
      );
}

/// AT.4 Manage Sports — multi-sport profile data. Presentation-first;
/// swap the local list for `profileProvider` mutation when wired.
class ManageSportsScreen extends StatefulWidget {
  const ManageSportsScreen({super.key});

  @override
  State<ManageSportsScreen> createState() => _ManageSportsScreenState();
}

class _ManageSportsScreenState extends State<ManageSportsScreen> {
  final List<SportEntry> _sports = [
    const SportEntry(
        sport: 'Cricket', role: 'Batsman', level: 'State', experience: '6 yrs', primary: true),
    const SportEntry(
        sport: 'Football', role: 'Midfielder', level: 'District', experience: '2 yrs'),
  ];

  void _setPrimary(int index) {
    setState(() {
      for (var i = 0; i < _sports.length; i++) {
        _sports[i] = _sports[i].copyWith(primary: i == index);
      }
    });
  }

  Future<void> _addSport() async {
    final added = await showModalBottomSheet<SportEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddSportSheet(),
    );
    if (added != null) setState(() => _sports.add(added));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Manage Sports', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            'Add every sport you play. Mark one as primary — it leads your profile.',
            style: GoogleFonts.inter(
                fontSize: 13, height: 1.45, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _sports.length; i++) _card(i),
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
    final s = _sports[index];
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
                child: const Icon(LucideIcons.dumbbell,
                    size: 20, color: AppColors.warnText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.sport,
                        style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text('${s.role} · ${s.level} · ${s.experience}',
                        style: GoogleFonts.inter(
                            fontSize: 12.5, color: AppColors.textSecondary)),
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
                  onPressed: () => setState(() => _sports.removeAt(index)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddSportSheet extends StatefulWidget {
  const _AddSportSheet();

  @override
  State<_AddSportSheet> createState() => _AddSportSheetState();
}

class _AddSportSheetState extends State<_AddSportSheet> {
  final _sport = TextEditingController();
  final _role = TextEditingController();
  final _experience = TextEditingController();
  String _level = 'District';

  static const _levels = ['School', 'District', 'State', 'National', 'International'];

  @override
  void dispose() {
    _sport.dispose();
    _role.dispose();
    _experience.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Add a sport',
                style: GoogleFonts.sora(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: 16),
            TextField(
              controller: _sport,
              decoration: const InputDecoration(labelText: 'Sport'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _role,
              decoration:
                  const InputDecoration(labelText: 'Playing role / position'),
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
              decoration:
                  const InputDecoration(labelText: 'Experience (e.g. 4 yrs)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Add sport',
                icon: LucideIcons.check,
                onPressed: () {
                  if (_sport.text.trim().isEmpty) return;
                  Navigator.of(context).pop(SportEntry(
                    sport: _sport.text.trim(),
                    role: _role.text.trim().isEmpty ? '—' : _role.text.trim(),
                    level: _level,
                    experience: _experience.text.trim().isEmpty
                        ? '—'
                        : _experience.text.trim(),
                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
