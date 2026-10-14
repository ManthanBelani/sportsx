import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_shortlist_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class TalentScoutShortlistScreen extends ConsumerStatefulWidget {
  const TalentScoutShortlistScreen({super.key});

  @override
  ConsumerState<TalentScoutShortlistScreen> createState() => _TalentScoutShortlistScreenState();
}

class _TalentScoutShortlistScreenState extends ConsumerState<TalentScoutShortlistScreen> {
  String _status = 'all';
  static const _tabs = ['all', 'under_review', 'final'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(scoutShortlistProvider.notifier).load(status: _status));
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final state = ref.watch(scoutShortlistProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('My Shortlist',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: _tabs.map((t) {
              final active = _status == t;
              final label = t == 'all' ? 'All' : t == 'under_review' ? 'Under Review' : 'Final';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _status = t);
                    ref.read(scoutShortlistProvider.notifier).load(status: t);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: active
                          ? const LinearGradient(colors: [
                              Color(0xFFFFD54A),
                              Color(0xFFFFC107),
                              Color(0xFFF5B400)
                            ])
                          : null,
                      color: active ? null : Colors.white,
                      border: Border.all(color: active ? const Color(0x2E785000) : AppColors.border),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(label,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.ink)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: state.isLoading && state.items.isEmpty
          ? const GenericListSkeleton()
          : state.error != null && state.items.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.border),
                    const SizedBox(height: 12),
                    Text(state.error!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    PrimaryButton(label: 'Retry', onPressed: () => ref.read(scoutShortlistProvider.notifier).load(status: _status)),
                  ]),
                )
              : state.items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(LucideIcons.star, size: 48, color: AppColors.border),
                          const SizedBox(height: 16),
                          const Text('No athletes shortlisted yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          const Text('Discover athletes and tap ⭐ to save for later', style: TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          PrimaryButton(label: 'Discover Athletes', icon: LucideIcons.search, onPressed: () => context.push('/scout-discovery')),
                        ]),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(scoutShortlistProvider.notifier).load(status: _status),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: state.items.length,
                        itemBuilder: (context, index) => _buildShortlistItem(context, ref, state.items[index]),
                      ),
                    ),
        ),
      ],
    ));
  }

  Widget _buildShortlistItem(BuildContext context, WidgetRef ref, dynamic item) {
    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove from Shortlist'),
          content: Text('Remove ${item.athlete.fullName} from your shortlist?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Remove')),
          ],
        ),
      ),
      onDismissed: (_) async {
        final success = await ref.read(scoutShortlistProvider.notifier).removeFromShortlist(item.athlete.id);
        if (context.mounted) {
          if (success) {
            SnackBarUtils.showSuccess(context, 'Removed from shortlist');
          } else {
            SnackBarUtils.showError(context, ref.read(scoutShortlistProvider).error ?? 'Failed to remove');
          }
        }
      },
      child: InkWell(
        onTap: () => context.push('/scout-athlete/${item.athlete.id}'),
        onLongPress: () => _showNotesDialog(context, ref, item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16), boxShadow: SportXShadows.e1),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              AthleteAvatar(photoUrl: item.athlete.photoUrl, radius: 24),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.athlete.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Row(children: [
                  if (item.athlete.sports.isNotEmpty)
                    Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: AppColors.infoLight, border: Border.all(color: AppColors.scout.withValues(alpha: 0.25)), borderRadius: BorderRadius.circular(999)), child: Text(item.athlete.sports.first, style: const TextStyle(fontSize: 11, color: AppColors.scout, fontWeight: FontWeight.w700))),
                  if (item.athlete.cityName != null) ...[const SizedBox(width: 6), Text(item.athlete.cityName!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))],
                ]),
              ])),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, size: 18, color: AppColors.textSecondary),
                onSelected: (v) {
                  if (v == 'notes') _showNotesDialog(context, ref, item);
                  if (v == 'view') context.push('/scout-athlete/${item.athlete.id}');
                  if (v == 'connect') context.push('/scout-connect/${item.athlete.id}');
                  if (v == 'remove') ref.read(scoutShortlistProvider.notifier).removeFromShortlist(item.athlete.id);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'view', child: Text('View profile')),
                  PopupMenuItem(value: 'notes', child: Text('Edit notes')),
                  PopupMenuItem(value: 'connect', child: Text('Connect')),
                  PopupMenuItem(value: 'remove', child: Text('Remove', style: TextStyle(color: Colors.red))),
                ],
              ),
            ]),
            if (item.notes != null && item.notes.toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16), boxShadow: SportXShadows.e1), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(LucideIcons.stickyNote, size: 14, color: AppColors.textSecondary), const SizedBox(width: 6), Expanded(child: Text(item.notes, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))])),
            ] else ...[
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: 'Add note',
                child: InkWell(
                  onTap: () => _showNotesDialog(context, ref, item),
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(LucideIcons.plus, size: 12, color: AppColors.scout), SizedBox(width: 4), Text('Add note', style: TextStyle(fontSize: 11, color: AppColors.scout, fontWeight: FontWeight.w500))]),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  void _showNotesDialog(BuildContext context, WidgetRef ref, dynamic item) {
    final ctrl = TextEditingController(text: item.notes ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Notes for ${item.athlete.fullName}'),
        content: TextField(controller: ctrl, maxLines: 4, decoration: const InputDecoration(hintText: 'e.g. Strong left-footed striker, observed at Junior Nationals...', border: OutlineInputBorder()), autofocus: true, maxLength: 1000),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          PrimaryButton(
            label: 'Save',
            small: true,
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref.read(scoutShortlistProvider.notifier).updateNotes(item.athlete.id, ctrl.text.trim());
              if (context.mounted) SnackBarUtils.showSuccess(context, ok ? 'Notes updated' : ref.read(scoutShortlistProvider).error ?? 'Failed to update notes');
            },
          ),
        ],
      ),
    );
  }
}
