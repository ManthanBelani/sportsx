import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class _Org {
  final String name;
  final String type;
  final String since;
  const _Org({required this.name, required this.type, required this.since});
}

/// AC.12 My Collaborations (P2) — partnerships with other orgs.
class AcademyCollaborationsScreen extends StatefulWidget {
  const AcademyCollaborationsScreen({super.key});

  @override
  State<AcademyCollaborationsScreen> createState() =>
      _AcademyCollaborationsScreenState();
}

class _AcademyCollaborationsScreenState
    extends State<AcademyCollaborationsScreen> {
  final List<_Org> _orgs = [
    const _Org(name: 'Elite Sports Foundation', type: 'Sponsor', since: '2023'),
    const _Org(name: 'City Sports Council', type: 'Government', since: '2021'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Collaborations', showBack: true),
      body: _orgs.isEmpty
          ? const EmptyState(
              icon: LucideIcons.handshake,
              title: 'No collaborations',
              message: 'Partnerships you form will appear here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                for (var i = 0; i < _orgs.length; i++) _card(i),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SecondaryButton(
                    label: 'Propose a collaboration',
                    icon: LucideIcons.plus,
                    onPressed: () => setState(() => _orgs.add(const _Org(
                        name: 'New Partner Org',
                        type: 'Pending',
                        since: '—'))),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _card(int index) {
    final o = _orgs[index];
    return SportXCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.building2,
                size: 20, color: AppColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.name,
                    style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('${o.type} · Since ${o.since}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _orgs.removeAt(index)),
            icon: const Icon(LucideIcons.x,
                size: 18, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
