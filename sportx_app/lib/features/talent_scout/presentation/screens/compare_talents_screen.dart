import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class CompareAthlete {
  final String name;
  final String meta;
  final int technical;
  final int fitness;
  final int matchAwareness;
  final int mental;
  const CompareAthlete({
    required this.name,
    required this.meta,
    required this.technical,
    required this.fitness,
    required this.matchAwareness,
    required this.mental,
  });

  int get overall =>
      ((technical + fitness + matchAwareness + mental) / 4).round();
}

/// SC.7 Compare Talents (P1) — side-by-side assessment of 2–3 athletes.
class CompareTalentsScreen extends StatelessWidget {
  final List<CompareAthlete> athletes;

  const CompareTalentsScreen({super.key, this.athletes = const []});

  static const _sample = [
    CompareAthlete(name: 'Arjun Patel', meta: 'Cricket · U-16', technical: 88, fitness: 76, matchAwareness: 82, mental: 79),
    CompareAthlete(name: 'Meera Nair', meta: 'Athletics · U-19', technical: 80, fitness: 92, matchAwareness: 74, mental: 85),
  ];

  @override
  Widget build(BuildContext context) {
    final list = athletes.isEmpty ? _sample : athletes;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Compare Talents', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: _column(list[i])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _column(CompareAthlete a) {
    return SportXCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.scout.withValues(alpha: 0.12),
            child: Text(a.name[0],
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.scout)),
          ),
          const SizedBox(height: 8),
          Text(a.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(a.meta,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _score('Overall', a.overall, highlight: true),
          _score('Technical', a.technical),
          _score('Fitness', a.fitness),
          _score('Match awareness', a.matchAwareness),
          _score('Mental', a.mental),
        ],
      ),
    );
  }

  Widget _score(String label, int value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textSecondary)),
              ),
              Text('$value',
                  style: GoogleFonts.sora(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFEDEFF2),
              valueColor: AlwaysStoppedAnimation<Color>(
                  highlight ? AppColors.yellowDeep : AppColors.scout),
            ),
          ),
        ],
      ),
    );
  }
}
