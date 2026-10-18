import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class _Staff {
  final String name;
  final String role;
  const _Staff({required this.name, required this.role});
}

/// AC.11 My Staff / Recruit Staff (P2).
class AcademyStaffScreen extends StatefulWidget {
  const AcademyStaffScreen({super.key});

  @override
  State<AcademyStaffScreen> createState() => _AcademyStaffScreenState();
}

class _AcademyStaffScreenState extends State<AcademyStaffScreen> {
  int _tab = 0;
  bool _posting = false;

  final _title = TextEditingController();
  final _role = TextEditingController();

  static const _staff = [
    _Staff(name: 'Coach Ravi Menon', role: 'Head Coach — Cricket'),
    _Staff(name: 'Dr. Anil Rao', role: 'Physiotherapist'),
    _Staff(name: 'Neha Gupta', role: 'Strength & Conditioning'),
  ];

  @override
  void dispose() {
    _title.dispose();
    _role.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Staff', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SegmentTabs(
            tabs: const ['Our Staff', 'Openings'],
            selectedIndex: _tab,
            onSelect: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 16),
          if (_tab == 0) ...[
            for (final s in _staff)
              SportXCard(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.coach.withValues(alpha: 0.12),
                      child: Text(s.name.split(' ').last[0],
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              color: AppColors.coach)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text(s.role,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight,
                        size: 18, color: AppColors.textTertiary),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                label: 'Post an opening',
                icon: LucideIcons.plus,
                onPressed: () => setState(() => _posting = !_posting),
              ),
            ),
          ] else
            const EmptyState(
              icon: LucideIcons.briefcase,
              title: 'No openings',
              message: 'Open roles you post will appear here.',
            ),
          if (_posting) ...[
            const SizedBox(height: 18),
            SportXCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New opening',
                      style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _role,
                    decoration:
                        const InputDecoration(labelText: 'Role / requirements'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Publish opening',
                      icon: LucideIcons.check,
                      onPressed: () {
                        setState(() {
                          _posting = false;
                          _title.clear();
                          _role.clear();
                          _tab = 1;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
