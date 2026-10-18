import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class _Slot {
  String time;
  String title;
  String venue;
  _Slot({required this.time, required this.title, required this.venue});
}

/// OR.9 Schedule Editor (P1) — fixtures / timetable for one event.
class ScheduleEditorScreen extends StatefulWidget {
  const ScheduleEditorScreen({super.key, this.eventTitle = 'Event'});

  final String eventTitle;

  @override
  State<ScheduleEditorScreen> createState() => _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends State<ScheduleEditorScreen> {
  final List<_Slot> _slots = [
    _Slot(time: '09:00', title: 'Opening ceremony', venue: 'Main Ground'),
    _Slot(time: '10:30', title: 'U-16 Quarterfinals', venue: 'Ground A'),
  ];

  Future<void> _addSlot() async {
    final time = TextEditingController();
    final title = TextEditingController();
    final venue = TextEditingController();
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
              Text('Add schedule slot',
                  style: GoogleFonts.sora(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 16),
              TextField(
                  controller: time,
                  decoration: const InputDecoration(
                      labelText: 'Time', hintText: 'e.g. 14:00')),
              const SizedBox(height: 12),
              TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Activity')),
              const SizedBox(height: 12),
              TextField(
                  controller: venue,
                  decoration: const InputDecoration(labelText: 'Venue')),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Add slot',
                  icon: LucideIcons.check,
                  onPressed: () {
                    if (title.text.trim().isEmpty) return;
                    _slots.add(_Slot(
                      time: time.text.trim().isEmpty ? '—' : time.text.trim(),
                      title: title.text.trim(),
                      venue: venue.text.trim().isEmpty ? '—' : venue.text.trim(),
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
      appBar: const SportXTopBar(title: 'Schedule', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(widget.eventTitle,
              style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 14),
          for (var i = 0; i < _slots.length; i++) _slotRow(i),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'Add slot',
              icon: LucideIcons.plus,
              onPressed: _addSlot,
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotRow(int index) {
    final s = _slots[index];
    return SportXCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.yellowTint,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(s.time,
                style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
          ),
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
                Text(s.venue,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _slots.removeAt(index)),
            icon: const Icon(LucideIcons.trash2,
                size: 18, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
