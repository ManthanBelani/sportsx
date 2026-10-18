import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class _Candidate {
  final String name;
  final String detail;
  final String ageGroup;
  const _Candidate({required this.name, required this.detail, required this.ageGroup});
}

/// AC.10 Add / Invite Athlete — link an athlete to the academy.
class InviteAthleteScreen extends StatefulWidget {
  const InviteAthleteScreen({super.key});

  @override
  State<InviteAthleteScreen> createState() => _InviteAthleteScreenState();
}

class _InviteAthleteScreenState extends State<InviteAthleteScreen> {
  final _search = TextEditingController();
  final _phone = TextEditingController();
  final Set<String> _invited = {};

  static const _candidates = [
    _Candidate(name: 'Arjun Patel', detail: 'Cricket · Gujarat', ageGroup: 'U-16'),
    _Candidate(name: 'Meera Nair', detail: 'Athletics · Kerala', ageGroup: 'U-19'),
    _Candidate(name: 'Rohit Sharma', detail: 'Football · Maharashtra', ageGroup: 'U-14'),
    _Candidate(name: 'Sana Khan', detail: 'Badminton · Delhi', ageGroup: 'U-19'),
  ];

  @override
  void dispose() {
    _search.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final results = _candidates
        .where((c) =>
            q.isEmpty ||
            c.name.toLowerCase().contains(q) ||
            c.detail.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Invite Athlete', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Search athletes',
              prefixIcon: Icon(LucideIcons.search),
            ),
          ),
          const SizedBox(height: 18),
          Text('Athletes on SportX',
              style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 12),
          if (results.isEmpty)
            const EmptyState(
              icon: LucideIcons.searchX,
              title: 'No matches',
              message: 'Try a different name or invite by phone below.',
            )
          else
            for (final c in results) _candidateRow(c),
          const SizedBox(height: 22),
          Text('Invite by phone',
              style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 12),
          SportXCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(LucideIcons.phone),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Send invite',
                    icon: LucideIcons.send,
                    onPressed: _phone.text.trim().isEmpty
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Invite sent — awaiting acceptance')),
                            );
                            _phone.clear();
                            setState(() {});
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _candidateRow(_Candidate c) {
    final invited = _invited.contains(c.name);
    return SportXCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.yellowTint,
            child: Text(c.name[0],
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, color: AppColors.ink)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('${c.detail} · ${c.ageGroup}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (invited)
            const StatusPill(label: 'INVITED', kind: PillKind.pending)
          else
            PrimaryButton(
              label: 'Invite',
              small: true,
              onPressed: () => setState(() => _invited.add(c.name)),
            ),
        ],
      ),
    );
  }
}
