import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/observation_provider.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/theme/colors.dart';

/// v3 SC.10 Observations — quick note + rating per athlete (private to scout).
class ObservationsScreen extends ConsumerStatefulWidget {
  final String? athleteProfileId;
  const ObservationsScreen({super.key, this.athleteProfileId});

  @override
  ConsumerState<ObservationsScreen> createState() => _ObservationsScreenState();
}

class _ObservationsScreenState extends ConsumerState<ObservationsScreen> {
  final _note = TextEditingController();
  int _rating = 4;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(observationsProvider(widget.athleteProfileId));
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        elevation: 0,
        title: Text('Observations',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add observation',
                  style: GoogleFonts.sora(fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) => IconButton(
                      icon: Icon(LucideIcons.star,
                          size: 22,
                          color: i < _rating ? AppColors.primaryDark : AppColors.border),
                      onPressed: () => setState(() => _rating = i + 1),
                    )),
              ),
              TextField(
                controller: _note,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Note (private to you)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          if (widget.athleteProfileId == null) {
                            SnackBarUtils.showError(context, 'Open from an athlete profile');
                            return;
                          }
                          setState(() => _saving = true);
                          final res = await addObservation(ref,
                              athleteProfileId: widget.athleteProfileId!,
                              rating: _rating,
                              note: _note.text.trim());
                          setState(() => _saving = false);
                          if (context.mounted) {
                            if (res != null) {
                              _note.clear();
                              SnackBarUtils.showSuccess(context, 'Observation saved');
                            } else {
                              SnackBarUtils.showError(context, 'Could not save');
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(_saving ? 'Saving…' : 'Save observation'),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          list.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            error: (e, _) => Text('Could not load observations',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
            data: (rows) => Column(
              children: rows.map((o) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(LucideIcons.eye, color: AppColors.primaryDarker),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('★ ${o['rating'] ?? '–'}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                          Text((o['note'] ?? '').toString(),
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                        ]),
                      ),
                    ]),
                  )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// v3 SC.13 contact sheet — purpose + guardian notice for U-18.
Future<void> showContactAthleteSheet(BuildContext context, WidgetRef ref, String athleteProfileId) async {
  final purpose = TextEditingController();
  final result = await showModalBottomSheet<Map<String, dynamic>?>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Contact athlete', style: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 6),
        Text('For athletes under 18 the request routes to the guardian; chat unlocks after guardian consent.',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 10),
        TextField(controller: purpose, maxLines: 3, decoration: const InputDecoration(hintText: 'Purpose (e.g. U-16 trial invite)', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final res = await contactAthlete(ref,
                  athleteProfileId: athleteProfileId, purpose: purpose.text.trim());
              if (ctx.mounted) Navigator.pop(ctx, res);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.ink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Send request'),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    ),
  );
  if (context.mounted && result != null && (result['guardian_review'] == true)) {
    SnackBarUtils.showSuccess(context, 'Sent — guardian review required (U-18)');
  } else if (context.mounted && result != null) {
    SnackBarUtils.showSuccess(context, 'Contact request sent');
  }
}
