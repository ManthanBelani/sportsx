import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// AD.11 Leaderboard Config (P1) — point weights & season reset.
class AdminLeaderboardConfigScreen extends StatefulWidget {
  const AdminLeaderboardConfigScreen({super.key});

  @override
  State<AdminLeaderboardConfigScreen> createState() =>
      _AdminLeaderboardConfigScreenState();
}

class _AdminLeaderboardConfigScreenState
    extends State<AdminLeaderboardConfigScreen> {
  final Map<String, int> _weights = {
    'Profile completion': 100,
    'Achievements': 50,
    'Posting activity': 10,
    'Events & trials': 25,
    'Connections': 5,
  };
  String _season = 'Season 2026';
  bool _autoReset = true;

  static const _seasons = ['Season 2026', 'Season 2025'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Leaderboard Config', showBack: true),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                Text('Point weights',
                    style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 12),
                for (final key in _weights.keys) _weightRow(key),
                const SizedBox(height: 18),
                Text('Season',
                    style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 12),
                SportXCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _season,
                        decoration:
                            const InputDecoration(labelText: 'Active season'),
                        items: _seasons
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _season = v ?? _season),
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Auto-reset each season',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                        value: _autoReset,
                        activeThumbColor: AppColors.ink,
                        onChanged: (v) => setState(() => _autoReset = v),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: SecondaryButton(
                          label: 'Reset leaderboard now',
                          icon: LucideIcons.rotateCcw,
                          onPressed: () => SnackBarUtils.showSuccess(
                              context, 'Leaderboard reset scheduled'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Save configuration',
                  icon: LucideIcons.check,
                  onPressed: () {
                    SnackBarUtils.showSuccess(context, 'Configuration saved');
                    Navigator.of(context).maybePop();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightRow(String key) {
    return SportXCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(key,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
              ),
              Text('${_weights[key]} pts',
                  style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
            ],
          ),
          Slider(
            value: _weights[key]!.toDouble(),
            min: 0,
            max: 200,
            divisions: 40,
            activeColor: AppColors.yellow,
            label: '${_weights[key]}',
            onChanged: (v) => setState(() => _weights[key] = v.round()),
          ),
        ],
      ),
    );
  }
}
