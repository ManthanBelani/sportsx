import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class _ExpiryRule {
  final String record;
  final int days;
  final bool enabled;
  const _ExpiryRule({
    required this.record,
    required this.days,
    this.enabled = true,
  });

  _ExpiryRule copyWith({int? days, bool? enabled}) => _ExpiryRule(
        record: record,
        days: days ?? this.days,
        enabled: enabled ?? this.enabled,
      );
}

/// AD.10 Expiry Rules — auto-expire listings after N days.
class AdminExpiryRulesScreen extends StatefulWidget {
  const AdminExpiryRulesScreen({super.key});

  @override
  State<AdminExpiryRulesScreen> createState() => _AdminExpiryRulesScreenState();
}

class _AdminExpiryRulesScreenState extends State<AdminExpiryRulesScreen> {
  final List<_ExpiryRule> _rules = [
    const _ExpiryRule(record: 'Events / Trials', days: 90),
    const _ExpiryRule(record: 'Opportunities', days: 60),
    const _ExpiryRule(record: 'Programs', days: 120),
    const _ExpiryRule(record: 'Facilities', days: 365, enabled: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Expiry Rules', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Listings auto-expire after the configured period unless renewed.',
            style: GoogleFonts.inter(
                fontSize: 13, height: 1.45, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _rules.length; i++) _row(i),
        ],
      ),
    );
  }

  Widget _row(int index) {
    final r = _rules[index];
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
            child: const Icon(LucideIcons.timerOff,
                size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.record,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _stepBtn(LucideIcons.minus, () {
                      setState(() => _rules[index] =
                          r.copyWith(days: (r.days - 15).clamp(15, 730)));
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('${r.days} days',
                          style: GoogleFonts.inter(
                              fontSize: 12.5, color: AppColors.textSecondary)),
                    ),
                    _stepBtn(LucideIcons.plus, () {
                      setState(() => _rules[index] =
                          r.copyWith(days: (r.days + 15).clamp(15, 730)));
                    }),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: r.enabled,
            activeThumbColor: AppColors.ink,
            onChanged: (v) =>
                setState(() => _rules[index] = r.copyWith(enabled: v)),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
      ),
    );
  }
}
