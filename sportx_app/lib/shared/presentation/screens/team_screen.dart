import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class TeamMember {
  final String name;
  final String role; // player role / position
  final String? photoUrl;
  const TeamMember({required this.name, required this.role, this.photoUrl});
}

/// D.17 Team Page (P2) — team overview, roster and open spots.
class TeamScreen extends StatelessWidget {
  final String name;
  final String sport;
  final String coach;
  final int openSpots;
  final List<TeamMember> members;

  const TeamScreen({
    super.key,
    required this.name,
    this.sport = 'Football',
    this.coach = 'Coach',
    this.openSpots = 0,
    this.members = const [],
  });

  @override
  Widget build(BuildContext context) {
    final roster = members.isEmpty ? _sample : members;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Team', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SportXCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(LucideIcons.shield,
                          size: 24, color: AppColors.info),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: GoogleFonts.sora(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text('$sport · Coach $coach',
                              style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (openSpots > 0)
                      StatusPill(
                          label: '$openSpots OPEN',
                          kind: PillKind.pending),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: openSpots > 0 ? 'Apply to join' : 'Request to join',
                        icon: LucideIcons.userPlus,
                        small: true,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    SecondaryButton(
                      label: 'Share',
                      icon: LucideIcons.share2,
                      onPressed: () => context.push('/media-viewer',
                          extra: {'media': const <String>[], 'title': 'Share team'}),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text('Roster',
                  style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const Spacer(),
              Text('${roster.length} members',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          for (final m in roster)
            SportXCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.yellowTint,
                    backgroundImage: (m.photoUrl != null && m.photoUrl!.isNotEmpty)
                        ? NetworkImage(m.photoUrl!)
                        : null,
                    child: (m.photoUrl == null || m.photoUrl!.isEmpty)
                        ? Text(
                            m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(m.name,
                        style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink)),
                  ),
                  Text(m.role,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          if (openSpots > 0) ...[
            const SizedBox(height: 8),
            const EmptyState(
              icon: LucideIcons.userPlus,
              title: 'Open spots available',
              message: 'Apply to join this team.',
            ),
          ],
        ],
      ),
    );
  }

  static const _sample = [
    TeamMember(name: 'Arjun Patel', role: 'Goalkeeper'),
    TeamMember(name: 'Vikram Singh', role: 'Defender'),
    TeamMember(name: 'Karan Mehta', role: 'Midfielder'),
    TeamMember(name: 'Rohit Sharma', role: 'Forward'),
  ];
}
