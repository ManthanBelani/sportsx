import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// OR.15 Promote Event (P2) — boost placement & duration.
class PromoteEventScreen extends StatefulWidget {
  const PromoteEventScreen({super.key});

  @override
  State<PromoteEventScreen> createState() => _PromoteEventScreenState();
}

class _PromoteEventScreenState extends State<PromoteEventScreen> {
  int _placement = 1;
  int _days = 7;

  static const _placements = [
    ('Explore banner', 'Appear at the top of Explore', '₹1,499'),
    ('Featured card', 'Highlighted card in search', '₹899'),
    ('Feed boost', 'Promoted in the community feed', '₹499'),
  ];

  @override
  Widget build(BuildContext context) {
    final total = _days * (299 + _placement * 200);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Promote Event', showBack: true),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                Text('Choose a placement',
                    style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 12),
                for (var i = 0; i < _placements.length; i++) _option(i),
                const SizedBox(height: 18),
                Text('Duration',
                    style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 12),
                SportXCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('$_days days',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink)),
                          const Spacer(),
                          Text('₹$total',
                              style: GoogleFonts.sora(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink)),
                        ],
                      ),
                      Slider(
                        value: _days.toDouble(),
                        min: 3,
                        max: 30,
                        divisions: 27,
                        activeColor: AppColors.yellow,
                        label: '$_days days',
                        onChanged: (v) => setState(() => _days = v.round()),
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
                  label: 'Promote for ₹$total',
                  icon: LucideIcons.rocket,
                  onPressed: () {
                    SnackBarUtils.showSuccess(
                        context, 'Promotion scheduled');
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

  Widget _option(int index) {
    final selected = index == _placement;
    final p = _placements[index];
    return GestureDetector(
      onTap: () => setState(() => _placement = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: selected ? AppColors.yellowDeep : AppColors.border,
              width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        child: Row(
          children: [
            Icon(
              selected ? LucideIcons.check : LucideIcons.circle,
              size: 20,
              color: selected ? AppColors.yellowDeep : AppColors.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.$1,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(p.$2,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(p.$3,
                style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark)),
          ],
        ),
      ),
    );
  }
}
