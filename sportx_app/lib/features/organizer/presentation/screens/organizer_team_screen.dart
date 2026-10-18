import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class _Member {
  final String name;
  final String role;
  final bool pending;
  const _Member({required this.name, required this.role, this.pending = false});
}

/// OR.16 My Team / Staff (P2) — add co-organizers with roles.
class OrganizerTeamScreen extends StatefulWidget {
  const OrganizerTeamScreen({super.key});

  @override
  State<OrganizerTeamScreen> createState() => _OrganizerTeamScreenState();
}

class _OrganizerTeamScreenState extends State<OrganizerTeamScreen> {
  final List<_Member> _members = [
    const _Member(name: 'Aisha Verma', role: 'Co-organizer'),
    const _Member(name: 'Samir Joshi', role: 'Volunteer lead', pending: true),
  ];

  Future<void> _invite() async {
    final name = TextEditingController();
    final role = TextEditingController();
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
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
              Text('Invite member',
                  style: GoogleFonts.sora(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 16),
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name / email')),
              const SizedBox(height: 12),
              TextField(
                  controller: role,
                  decoration: const InputDecoration(labelText: 'Role')),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Send invite',
                  icon: LucideIcons.send,
                  onPressed: () {
                    if (name.text.trim().isEmpty) return;
                    _members.add(_Member(
                      name: name.text.trim(),
                      role: role.text.trim().isEmpty
                          ? 'Co-organizer'
                          : role.text.trim(),
                      pending: true,
                    ));
                    Navigator.of(ctx).pop(true);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (added == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'My Team', showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.ink,
        onPressed: _invite,
        icon: const Icon(LucideIcons.userPlus),
        label: Text('Invite',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          for (final m in _members)
            SportXCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.organizer.withValues(alpha: 0.12),
                    child: Text(m.name[0],
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            color: AppColors.organizer)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name,
                            style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                        const SizedBox(height: 2),
                        Text(m.role,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (m.pending)
                    const StatusPill(label: 'INVITED', kind: PillKind.pending),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
