import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class MyTournamentsManagementScreen extends ConsumerWidget {
  const MyTournamentsManagementScreen({super.key});

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myTournamentsProvider);
    final published = state.items.where((t)=> t.status=='published' || t.status=='active').toList();
    final drafts = state.items.where((t)=> t.status=='draft').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: ()=> context.pop()),
        title: const Text('My Tournaments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton(
              onPressed: ()=> context.push('/post-tournament'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
              child: const Text('+ New', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: RefreshIndicator(
        onRefresh: ()=> ref.read(myTournamentsProvider.notifier).refresh(),
        child: state.isLoading && state.items.isEmpty
            ? const GenericListSkeleton()
            : state.items.isEmpty
                ? ListView(children: const [SizedBox(height: 200), Center(child: Text('No tournaments yet', style: TextStyle(color: AppColors.textSecondary)))])
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (published.isNotEmpty) ...[
                        Text('PUBLISHED (${published.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        ...published.map((t)=> Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _tournamentCard(context, ref, t, true),
                        )),
                      ],
                      if (drafts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('DRAFTS (${drafts.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        ...drafts.map((t)=> Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _tournamentCard(context, ref, t, false),
                        )),
                      ],
                      if (published.isEmpty && drafts.isEmpty)
                        const Center(child: Text('No tournaments', style: TextStyle(color: AppColors.textSecondary))),
                    ],
                  ),
      ),
    );
  }

  Widget _tournamentCard(BuildContext context, WidgetRef ref, dynamic t, bool isPublished) {
    final title = t.title as String;
    final id = t.id.toString();
    final status = t.status as String;
    final start = t.startDate as DateTime?;
    final end = t.endDate as DateTime?;
    final venue = t.venue as String?;
    final dateStr = start!=null ? (end!=null ? '${_fmt(start)}-${_fmt(end)}, ${end.year} • ${venue ?? ''}' : '${_fmt(start)} • ${venue ?? ''}') : (venue ?? '');
    final badgeColor = isPublished ? const Color(0xFFd1fae5) : const Color(0xFFfef3c7);
    final badgeText = isPublished ? const Color(0xFF065f46) : const Color(0xFF92400e);

    final filled = t.filledSpots as int? ?? 0;
    final fee = t.registrationFee as double?;
    final collected = fee!=null ? fee*filled : 0;

    return InkWell(
      onTap: ()=> context.push('/registration-management', extra: {'id': id, 'title': title}),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: const Icon(LucideIcons.trophy, size: 22, color: AppColors.textPrimary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(dateStr.trim(), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)), child: Text(_capitalize(status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: badgeText))),
          ]),
          if (isPublished) ...[
            const SizedBox(height: 12),
            Row(children: [
              Text.rich(TextSpan(children:[
                TextSpan(text: '$filled', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const TextSpan(text: ' teams registered', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ])),
              const SizedBox(width: 20),
              Text.rich(TextSpan(children:[
                TextSpan(text: '₹${collected.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const TextSpan(text: ' collected', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ])),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, size: 16, color: AppColors.textSecondary),
                onSelected: (v) async {
                  final actions = ref.read(providerTournamentActionsProvider);
                  switch(v){
                    case 'registrations': context.push('/registration-management', extra:{'id':id,'title':title}); break;
                    case 'capacity': context.push('/capacity-management', extra:{'id':id}); break;
                    case 'results': context.push('/results-publishing', extra:{'id':id,'title':title}); break;
                    case 'publish': await actions.publish(id); break;
                    case 'close': await actions.close(id); break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'registrations', child: Text('Registrations')),
                  const PopupMenuItem(value: 'capacity', child: Text('Capacity')),
                  const PopupMenuItem(value: 'results', child: Text('Results')),
                  if (status=='draft') const PopupMenuItem(value: 'publish', child: Text('Publish')),
                  if (status=='published') const PopupMenuItem(value: 'close', child: Text('Close')),
                ],
              ),
            ]),
            // capacity section per design - show first category example
            if (t.categories != null && (t.categories as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              ... (t.categories as List).take(1).map((cat){
                final cap = cat.capacity as int? ?? 16;
                final isFull = filled >= cap;
                return Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
                    Text('${cat.name}: $filled/$cap teams', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(isFull ? 'Full' : '${cap-filled} left', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: cap==0?0: (filled/cap).clamp(0,1), minHeight: 6, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.primary))),
                ]);
              }),
            ],
          ],
        ]),
      ),
    );
  }

  String _fmt(DateTime d){
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month-1]} ${d.day}';
  }
}