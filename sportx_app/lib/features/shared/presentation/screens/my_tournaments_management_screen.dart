import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/core/role_config.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class MyTournamentsManagementScreen extends ConsumerWidget {
  const MyTournamentsManagementScreen({super.key});

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myTournamentsProvider);
    final canCreate = canCreateListings(ref.watch(authProvider).user?.role);
    final published = state.items.where((t)=> t.status=='published' || t.status=='active').toList();
    final drafts = state.items.where((t)=> t.status=='draft').toList();
    final closed = state.items.where((t)=> t.status=='closed' || t.status=='expired').toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: ()=> context.pop()),
        title: Text('My Tournaments',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        actions: [
          if (canCreate)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton(
                onPressed: ()=> context.push('/post-tournament'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: AppColors.ink, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                child: const Text('+ New', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
                          child: _tournamentCard(context, ref, t, true, canCreate),
                        )),
                      ],
                      if (drafts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('DRAFTS (${drafts.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        ...drafts.map((t)=> Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _tournamentCard(context, ref, t, false, canCreate),
                        )),
                      ],
                      if (published.isEmpty && drafts.isEmpty && closed.isEmpty)
                        const Center(child: Text('No tournaments', style: TextStyle(color: AppColors.textSecondary))),
                      if (closed.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('CLOSED (${closed.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        ...closed.map((t)=> Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _tournamentCard(context, ref, t, false, canCreate),
                        )),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _tournamentCard(BuildContext context, WidgetRef ref, dynamic t, bool isPublished, bool canCreate) {
    final title = t.title as String;
    final id = t.id.toString();
    final status = t.status as String;
    final start = t.startDate as DateTime?;
    final end = t.endDate as DateTime?;
    final venue = t.venue as String?;
    final dateStr = start!=null ? (end!=null ? '${_fmt(start)}-${_fmt(end)}, ${end.year} • ${venue ?? ''}' : '${_fmt(start)} • ${venue ?? ''}') : (venue ?? '');

    // Real counters from the API (registration stats block).
    final confirmed = (t.confirmedRegistrationsCount as int?) ?? 0;
    final totalRegs = (t.registrationsCount as int?) ?? 0;
    final spots = (t.totalSpots as int?) ?? 0;
    final externalClicks = (t.externalRegistrationClicks as int?) ?? 0;
    final hasExternal = (t.hasExternalRegistration as bool?) ?? false;

    return InkWell(
      onTap: ()=> context.push('/registration-management', extra: {'id': id, 'title': title}),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: SportXShadows.e1),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.yellowTint, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: const Icon(LucideIcons.trophy, size: 22, color: AppColors.warnText)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(dateStr.trim(), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ])),
            StatusPill(label: _capitalize(status), kind: isPublished ? PillKind.ok : PillKind.pending),
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical, size: 16, color: AppColors.textSecondary),
              onSelected: (v) async {
                final actions = ref.read(providerTournamentActionsProvider);
                switch(v){
                  case 'edit': context.push('/edit-tournament/$id'); break;
                  case 'registrations': context.push('/registration-management', extra:{'id':id,'title':title}); break;
                  case 'capacity': context.push('/capacity-management', extra:{'id':id}); break;
                  case 'results': context.push('/results-publishing', extra:{'id':id,'title':title}); break;
                  case 'publish':
                    final (ok, error) = await actions.publish(id);
                    if (!context.mounted) return;
                    if (ok) {
                      SnackBarUtils.showSuccess(context, 'Tournament published');
                    } else {
                      SnackBarUtils.showError(context, error ?? 'Could not publish the tournament.');
                    }
                    break;
                  case 'close':
                    final (ok, error) = await actions.close(id);
                    if (!context.mounted) return;
                    if (ok) {
                      SnackBarUtils.showSuccess(context, 'Tournament closed');
                    } else {
                      SnackBarUtils.showError(context, error ?? 'Could not close the tournament.');
                    }
                    break;
                }
              },
              itemBuilder: (_) => [
                if (canCreate) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'registrations', child: Text('Registrations')),
                const PopupMenuItem(value: 'capacity', child: Text('Capacity')),
                const PopupMenuItem(value: 'results', child: Text('Results')),
                if (canCreate && status=='draft') const PopupMenuItem(value: 'publish', child: Text('Publish')),
                if (canCreate && status=='published') const PopupMenuItem(value: 'close', child: Text('Close')),
              ],
            ),
          ]),
          if (isPublished) ...[
            const SizedBox(height: 12),
            Row(children: [
              Text.rich(TextSpan(children:[
                TextSpan(text: '$confirmed', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                TextSpan(text: spots > 0 ? ' of $spots spots filled' : ' confirmed', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ])),
              const SizedBox(width: 20),
              if (!hasExternal)
                Text.rich(TextSpan(children:[
                  TextSpan(text: '$totalRegs', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const TextSpan(text: ' registration requests', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ])),
            ]),
            // External registration page — clicks are NOT registrations.
            if (hasExternal) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  const Icon(LucideIcons.externalLink, size: 14, color: AppColors.info),
                  const SizedBox(width: 6),
                  const Expanded(child: Text('External registration page', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.info))),
                  Text('$externalClicks clicks', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.info)),
                ]),
              ),
            ],
            // capacity section per design - show first category example
            if (!hasExternal && t.categories != null && (t.categories as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              ... (t.categories as List).take(1).map((cat){
                final cap = cat.capacity as int? ?? 16;
                final isFull = confirmed >= cap;
                return Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
                    Text('${cat.name}: $confirmed/$cap spots', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(isFull ? 'Full' : '${cap-confirmed} left', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: cap==0?0: (confirmed/cap).clamp(0,1), minHeight: 6, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.primary))),
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