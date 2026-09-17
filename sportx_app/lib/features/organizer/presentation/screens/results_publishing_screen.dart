import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
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
  void dispose(){ scoreA.dispose(); scoreB.dispose(); }
}

class _ResultsPublishingScreenState extends ConsumerState<ResultsPublishingScreen> {
  final List<_MatchEditing> _semi = [
    _MatchEditing(teamA: 'Rising Stars FC', teamB: 'Thunder United'),
    _MatchEditing(teamA: 'TBD', teamB: 'TBD'),
  ];
  bool _saving=false;
  List<Map<String,dynamic>> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState(){
    super.initState();
    _semi[0].scoreA.text='3';
    _semi[0].scoreB.text='1';
    _loadCategories();
  }
  @override
  void dispose(){
    for (final m in _semi) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try{
      final resp = await ref.read(dioProvider).get('/tournaments/${widget.tournamentId}/capacity');
      final raw = resp.data;
      List data = raw is Map && raw['data'] is List ? raw['data'] as List : [];
      setState(()=> _categories = data.map((e)=> Map<String,dynamic>.from(e as Map)).toList());
      if (_categories.isNotEmpty) _selectedCategoryId = (_categories.first['category_id'] ?? _categories.first['id']).toString();
    } catch (_){}
  }

  Future<void> _publish() async {
    if (_selectedCategoryId==null){
      SnackBarUtils.showError(context, 'No category selected');
      return;
    }
    // Determine winners from scores
    final winners = <Map<String,dynamic>>[];
    // For semi final match 1, winner is teamA if scoreA>scoreB else teamB
    for (int i=0;i<_semi.length;i++){
      final m = _semi[i];
      final a = int.tryParse(m.scoreA.text) ?? 0;
      final b = int.tryParse(m.scoreB.text) ?? 0;
      final hasScore = m.scoreA.text.isNotEmpty && m.scoreB.text.isNotEmpty;
      if (!hasScore) continue;
      final winner = a>=b ? m.teamA : m.teamB;
      // Only first match contributes to results for demo; map place 1..3
      if (i==0) {
        winners.add({'category_id': int.parse(_selectedCategoryId!), 'place': 1, 'winner_name': winner});
        final loser = a>=b ? m.teamB : m.teamA;
        winners.add({'category_id': int.parse(_selectedCategoryId!), 'place': 2, 'winner_name': loser});
      }
    }
    if (winners.isEmpty){
      SnackBarUtils.showError(context, 'Enter at least one result');
      return;
    }
    setState(()=> _saving=true);
    try{
      await ref.read(dioProvider).post('/tournaments/${widget.tournamentId}/results', data: {'results': winners});
      ref.invalidate(tournamentResultsProvider(widget.tournamentId));
      if (mounted){
        SnackBarUtils.showSuccess(context, 'Results published!');
        context.pop();
      }
    } catch(e){
      if (mounted) SnackBarUtils.showError(context, e, 'Failed to publish results. Please try again.');
    } finally{
      if (mounted) setState(()=> _saving=false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: ()=> context.pop()),
        title: const Text('Publish Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height:1,color: AppColors.border)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          // Tournament info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('U-16 Semi Finals • Dec 16, 2024', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              if (_categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category', isDense: true),
                  items: _categories.map((c)=> DropdownMenuItem(value: (c['category_id'] ?? c['id']).toString(), child: Text((c['category_name'] ?? c['name']).toString()))).toList(),
                  onChanged: (v)=> setState(()=> _selectedCategoryId=v),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 24),
          const Text('SEMI FINALS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _matchSection('Match 1 • Dec 16, 10:00 AM', _semi[0], true),
          const SizedBox(height: 16),
          _matchSection('Match 2 • Dec 16, 2:00 PM', _semi[1], false),
          const SizedBox(height: 24),
          const Text('QUARTER FINALS (COMPLETED)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          const Text('Match 1 • Dec 15, 9:00 AM', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(children:[
            const Expanded(child: _TeamSlot(text: 'Rising Stars FC', winner: true)),
            const SizedBox(width: 12),
            const Text('2 - 0', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(width: 12),
            const Expanded(child: _TeamSlot(text: 'Falcons SC', winner: false)),
          ]),
          const SizedBox(height: 32),
        ]),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20,16,20,16+MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
        child: SizedBox(width: double.infinity, child: FilledButton(
          onPressed: _saving? null: _publish,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.all(14)),
          child: _saving? const SizedBox(height:20,width:20, child: CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Text('Publish Results', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        )),
      ),
    );
  }

  Widget _matchSection(String round, _MatchEditing m, bool filled){
    final isTbd = m.teamA=='TBD';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text(round, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      Row(children:[
        Expanded(child: _TeamSlot(text: m.teamA, winner: filled && !isTbd, tbd: isTbd)),
        const SizedBox(width: 8),
        SizedBox(width: 60, child: TextField(controller: m.scoreA, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600), decoration: InputDecoration(hintText: '-', isDense: true, contentPadding: const EdgeInsets.symmetric(vertical:10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border))))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('-', style: TextStyle(fontSize:12, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
        SizedBox(width: 60, child: TextField(controller: m.scoreB, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600), decoration: InputDecoration(hintText: '-', isDense: true, contentPadding: const EdgeInsets.symmetric(vertical:10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border))))),
        const SizedBox(width: 8),
        Expanded(child: _TeamSlot(text: m.teamB, winner: false, tbd: isTbd)),
      ]),
    ]);
  }
}

class _TeamSlot extends StatelessWidget {
  final String text;
  final bool winner;
  final bool tbd;
  const _TeamSlot({required this.text, this.winner=false, this.tbd=false});
  @override
  Widget build(BuildContext context){
    Color bg = AppColors.surface;
    Color fg = AppColors.textPrimary;
    if (winner){ bg = const Color(0xFFd1fae5); fg = const Color(0xFF065f46);}
    if (tbd){ fg = AppColors.textSecondary; }
    return Container(
      padding: const EdgeInsets.symmetric(vertical:12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: fg), textAlign: TextAlign.center),
    );
  }
}
