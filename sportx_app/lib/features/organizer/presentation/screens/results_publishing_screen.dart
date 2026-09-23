import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class ResultsPublishingScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String title;
  const ResultsPublishingScreen({super.key, required this.tournamentId, required this.title});

  @override
  ConsumerState<ResultsPublishingScreen> createState() => _ResultsPublishingScreenState();
}

class _MatchEditing {
  String teamA;
  String teamB;
  TextEditingController scoreA = TextEditingController();
  TextEditingController scoreB = TextEditingController();
  _MatchEditing({required this.teamA, required this.teamB});
  void dispose() { scoreA.dispose(); scoreB.dispose(); }
}

class _ResultsPublishingScreenState extends ConsumerState<ResultsPublishingScreen> {
  List<_MatchEditing> _matches = [];
  bool _saving = false;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    for (final m in _matches) m.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final resp = await ref.read(dioProvider).get('/tournaments/${widget.tournamentId}/capacity');
      final raw = resp.data;
      List data = raw is Map && raw['data'] is List ? raw['data'] as List : [];
      final cats = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() {
        _categories = cats;
        if (_categories.isNotEmpty) {
          _selectedCategoryId = (_categories.first['category_id'] ?? _categories.first['id']).toString();
        }
      });
      if (_selectedCategoryId != null) _loadApprovedTeams();
    } catch (_) {}
  }

  Future<void> _loadApprovedTeams() async {
    if (_selectedCategoryId == null) return;
    try {
      // fetch approved registrations for this tournament
      final regs = await ref.read(tournamentRegistrationsByStatusProvider((tournamentId: widget.tournamentId, status: 'approved')).future);
      // filter by selected category
      final filtered = regs.where((r) {
        final catId = (r['category'] is Map ? r['category']['id'] : r['category_id'])?.toString();
        return catId == _selectedCategoryId;
      }).toList();
      // dispose old
      for (final m in _matches) m.dispose();
      final newMatches = <_MatchEditing>[];
      // pair teams sequentially
      for (int i = 0; i < filtered.length; i += 2) {
        final a = _teamName(filtered[i]);
        final b = i + 1 < filtered.length ? _teamName(filtered[i + 1]) : 'TBD';
        newMatches.add(_MatchEditing(teamA: a, teamB: b));
      }
      if (newMatches.isEmpty) {
        // fallback: show empty pair to allow manual entry if no approved teams yet
        newMatches.add(_MatchEditing(teamA: 'Team A', teamB: 'Team B'));
      }
      setState(() => _matches = newMatches);
    } catch (_) {
      // fallback to one empty match
      setState(() => _matches = [_MatchEditing(teamA: 'Team A', teamB: 'Team B')]);
    }
  }

  String _teamName(Map<String, dynamic> r) {
    final athlete = r['athlete'] is Map ? r['athlete'] as Map : null;
    final user = athlete != null && athlete['user'] is Map ? athlete['user'] as Map : null;
    return (r['team_name'] ?? user?['name'] ?? 'Team').toString();
  }

  Future<void> _publish() async {
    if (_selectedCategoryId == null) {
      SnackBarUtils.showError(context, 'No category selected');
      return;
    }
    if (_matches.isEmpty) {
      SnackBarUtils.showError(context, 'No matches to publish');
      return;
    }
    final winners = <Map<String, dynamic>>[];
    for (final m in _matches) {
      final a = int.tryParse(m.scoreA.text) ?? -1;
      final b = int.tryParse(m.scoreB.text) ?? -1;
      final hasScore = m.scoreA.text.isNotEmpty && m.scoreB.text.isNotEmpty && a >= 0 && b >= 0;
      if (!hasScore) continue;
      if (m.teamA == 'TBD' || m.teamB == 'TBD') continue;
      if (m.teamA == 'Team A' || m.teamB == 'Team B') {
        SnackBarUtils.showError(context, 'No approved teams found for selected category. Approve registrations first.');
        return;
      }
      final winner = a >= b ? m.teamA : m.teamB;
      final loser = a >= b ? m.teamB : m.teamA;
      winners.add({'category_id': int.parse(_selectedCategoryId!), 'place': 1, 'winner_name': winner});
      winners.add({'category_id': int.parse(_selectedCategoryId!), 'place': 2, 'winner_name': loser});
      break; // only first completed match as final result for now
    }
    if (winners.isEmpty) {
      SnackBarUtils.showError(context, 'Enter scores for at least one completed match');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).post('/tournaments/${widget.tournamentId}/results', data: {'results': winners});
      ref.invalidate(tournamentResultsProvider(widget.tournamentId));
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Results published!');
        context.pop();
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e, 'Failed to publish results. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final approvedAsync = _selectedCategoryId == null ? null : ref.watch(tournamentRegistrationsByStatusProvider((tournamentId: widget.tournamentId, status: 'approved')));
    final approvedCount = approvedAsync?.valueOrNull?.where((r) {
          final catId = (r['category'] is Map ? r['category']['id'] : r['category_id'])?.toString();
          return catId == _selectedCategoryId;
        }).length ??
        0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Publish Results', style: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: SportXShadows.e1,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text('$approvedCount approved team${approvedCount == 1 ? '' : 's'} • Select category to publish results', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              if (_categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category', isDense: true),
                  items: _categories.map((c) => DropdownMenuItem(value: (c['category_id'] ?? c['id']).toString(), child: Text((c['category_name'] ?? c['name']).toString()))).toList(),
                  onChanged: (v) {
                    setState(() => _selectedCategoryId = v);
                    _loadApprovedTeams();
                  },
                ),
              ],
              if (_categories.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('No categories found. Create tournament categories first.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            ]),
          ),
          const SizedBox(height: 24),
          if (approvedCount == 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.yellowTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.yellowDeep.withValues(alpha: 0.35)),
              ),
              child: Row(children: [Icon(LucideIcons.triangleAlert, size: 16, color: AppColors.warnText), SizedBox(width: 8), Expanded(child: Text('No approved registrations in this category yet. Approve teams in Registrations first.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.warnText)))]),
            )
          else ...[
            Text('MATCHES (${_matches.length})', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            ..._matches.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _matchSection('Match ${e.key + 1}', e.value))),
          ],
          const SizedBox(height: 32),
        ]),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
        child: SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: 'Publish Results',
            icon: LucideIcons.trophy,
            onPressed: _saving ? null : _publish,
          ),
        ),
      ),
    );
  }

  Widget _matchSection(String round, _MatchEditing m) {
    final isTbd = m.teamA == 'TBD' || m.teamB == 'TBD' || m.teamA == 'Team A';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(round, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _TeamSlot(text: m.teamA, tbd: isTbd)),
        const SizedBox(width: 8),
        SizedBox(width: 60, child: TextField(controller: m.scoreA, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600), decoration: InputDecoration(hintText: '-', isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border))))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('-', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
        SizedBox(width: 60, child: TextField(controller: m.scoreB, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600), decoration: InputDecoration(hintText: '-', isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border))))),
        const SizedBox(width: 8),
        Expanded(child: _TeamSlot(text: m.teamB, tbd: isTbd)),
      ]),
    ]);
  }
}

class _TeamSlot extends StatelessWidget {
  final String text;
  final bool tbd;
  const _TeamSlot({required this.text, this.tbd = false});
  @override
  Widget build(BuildContext context) {
    Color bg = Colors.white;
    Color fg = AppColors.ink;
    if (tbd) fg = AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: SportXShadows.e1,
      ),
      alignment: Alignment.center,
      child: Text(text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: fg), textAlign: TextAlign.center),
    );
  }
}
