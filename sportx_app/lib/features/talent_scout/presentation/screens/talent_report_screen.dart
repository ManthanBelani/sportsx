import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// SC.8 Talent Report (P1) — structured evaluation of one athlete.
class TalentReportScreen extends StatefulWidget {
  final String athleteName;
  final String meta;

  const TalentReportScreen({
    super.key,
    this.athleteName = 'Arjun Patel',
    this.meta = 'Cricket · Batsman · U-16 · Gujarat',
  });

  @override
  State<TalentReportScreen> createState() => _TalentReportScreenState();
}

class _TalentReportScreenState extends State<TalentReportScreen> {
  int _tab = 0;
  static const _tabs = ['Overview', 'Performance', 'Potential', 'Notes'];

  final _notes = TextEditingController();

  static const _scores = [
    ('Technical', 88),
    ('Fitness', 76),
    ('Match awareness', 82),
    ('Mental', 79),
  ];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  int get _overall =>
      (_scores.fold<int>(0, (s, e) => s + e.$2) / _scores.length).round();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Talent Report', showBack: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.scout.withValues(alpha: 0.12),
                      child: Text(widget.athleteName[0],
                          style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.scout)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.athleteName,
                              style: GoogleFonts.sora(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text(widget.meta,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.yellowTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text('$_overall',
                              style: GoogleFonts.sora(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink)),
                          Text('Overall',
                              style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentTabs(
                  tabs: _tabs,
                  selectedIndex: _tab,
                  onSelect: (i) => setState(() => _tab = i),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [_body()],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Save to Shortlist',
                  icon: LucideIcons.listPlus,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to shortlist')),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_tab) {
      case 0:
        return SportXCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Key information',
                  style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 10),
              _kv('Primary sport', 'Cricket'),
              _kv('Playing role', 'Top-order batsman'),
              _kv('Level', 'State U-16'),
              _kv('Experience', '6 years'),
              _kv('Location', 'Ahmedabad, Gujarat'),
            ],
          ),
        );
      case 1:
        return SportXCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assessment',
                  style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 14),
              for (final s in _scores) _bar(s.$1, s.$2),
            ],
          ),
        );
      case 2:
        return SportXCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Conclusion',
                  style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 8),
              const StatusPill(label: 'HIGH POTENTIAL', kind: PillKind.feat),
              const SizedBox(height: 10),
              Text(
                'Strong technical base with consistent match temperament. '
                'Recommend tracking at the state level and inviting to '
                'upcoming trials.',
                style: GoogleFonts.inter(
                    fontSize: 13.5, height: 1.5, color: AppColors.dark),
              ),
            ],
          ),
        );
      default:
        return SportXCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scout notes',
                  style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                maxLines: 6,
                decoration: const InputDecoration(
                    hintText: 'Private notes about this athlete…',
                    alignLabelWithHint: true),
              ),
            ],
          ),
        );
    }
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(k,
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(v,
                style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink)),
          ),
        ],
      ),
    );
  }

  Widget _bar(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.dark)),
              ),
              Text('$value',
                  style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFEDEFF2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFF5B400)),
            ),
          ),
        ],
      ),
    );
  }
}
