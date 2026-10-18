import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class _Session {
  final String title;
  final String when;
  const _Session({required this.title, required this.when});
}

/// CO.8 Go Live / Webinar (P2) — schedule and host a live session.
class CoachGoLiveScreen extends StatefulWidget {
  const CoachGoLiveScreen({super.key});

  @override
  State<CoachGoLiveScreen> createState() => _CoachGoLiveScreenState();
}

class _CoachGoLiveScreenState extends State<CoachGoLiveScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime? _when;
  bool _live = false;

  final List<_Session> _scheduled = const [
    _Session(title: 'Batting Fundamentals — Live Q&A', when: 'Tomorrow · 6:00 PM'),
    _Session(title: 'Strength & Conditioning', when: 'Sat · 7:30 AM'),
  ];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _when ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null) return;
    setState(() => _when =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final canStart = _title.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Go Live', showBack: true),
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
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(LucideIcons.radio,
                          size: 22, color: AppColors.error),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Host a live session',
                          style: GoogleFonts.sora(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                    ),
                    if (_live)
                      const StatusPill(label: 'LIVE', kind: PillKind.no),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _title,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      labelText: 'Session title',
                      hintText: 'e.g. Batting fundamentals'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Schedule',
                        prefixIcon: Icon(LucideIcons.calendarClock)),
                    child: Text(
                      _when == null
                          ? 'Pick date & time'
                          : '${_when!.day}/${_when!.month}/${_when!.year} · '
                              '${_when!.hour.toString().padLeft(2, '0')}:${_when!.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(
                          fontSize: 13.5, color: AppColors.ink),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: _live
                      ? SecondaryButton(
                          label: 'End session',
                          icon: LucideIcons.square,
                          onPressed: () => setState(() => _live = false),
                        )
                      : PrimaryButton(
                          label: 'Start live now',
                          icon: LucideIcons.video,
                          onPressed: canStart
                              ? () => setState(() => _live = true)
                              : null,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Scheduled',
              style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 12),
          for (final s in _scheduled)
            SportXCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(LucideIcons.clock,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                        const SizedBox(height: 2),
                        Text(s.when,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const StatusPill(label: 'SCHEDULED', kind: PillKind.info),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
