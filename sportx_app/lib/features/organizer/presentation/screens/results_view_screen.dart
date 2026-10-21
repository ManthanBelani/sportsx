import 'package:flutter/material.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class ResultsViewScreen extends ConsumerWidget {
  final String tournamentId;
  final String title;
  const ResultsViewScreen({super.key, required this.tournamentId, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tournamentResultsProvider(tournamentId));
    final results = async.valueOrNull ?? [];

    // The API returns {place, winner_name, category, published_at}.
    String nameOf(dynamic entry) {
      final m = entry as Map;
      return (m['winner_name'] ?? m['winner'] ?? m['team_name'] ?? m['name'] ?? '—').toString();
    }

    int placeOf(dynamic entry) {
      final m = entry as Map;
      final place = m['place'];
      if (place is num) return place.round();
      return int.tryParse(place?.toString() ?? '') ?? 0;
    }

    String categoryOf(dynamic entry) {
      final m = entry as Map;
      final category = m['category'];
      if (category is Map && category['name'] != null) return category['name'].toString();
      return (m['category_name'] ?? 'All categories').toString();
    }

    bool isPublished(dynamic entry) {
      final m = entry as Map;
      return m['published_at'] != null;
    }

    // Sorted by place so the podium is always 1st, 2nd, 3rd.
    final ordered = [...results]..sort((a, b) => placeOf(a).compareTo(placeOf(b)));

    Widget medalFor(int index, String label) {
      final emoji = ['🥇', '🥈', '🥉'][index];
      final entry = index < ordered.length ? ordered[index] : null;
      final name = entry == null ? '—' : nameOf(entry);
      return Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(name, style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        StatusPill(label: label, kind: index == 0 ? PillKind.feat : PillKind.draft),
      ]);
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text('$title — Results',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: AppColors.border)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(tournamentResultsProvider(tournamentId)),
        child: async.when(
          loading: () => const GenericListSkeleton(),
          error: (e, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(ApiException.messageFor(e), style: GoogleFonts.inter(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              SecondaryButton(label: 'Retry', onPressed: () => ref.invalidate(tournamentResultsProvider(tournamentId))),
            ]),
          ),
          data: (_) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 120),
                    child: Center(child: Text('Results not published yet', style: GoogleFonts.inter(color: AppColors.textSecondary))),
                  )
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: SportXShadows.e1,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: medalFor(0, 'Winner')),
                            Expanded(child: medalFor(1, 'Runner-up')),
                            Expanded(child: medalFor(2, '3rd Place')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Full Standings', style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ),
                      const SizedBox(height: 12),
                      ...ordered.asMap().entries.map((e) => EntityRow(
                            title: nameOf(e.value),
                            subtitle: [
                              'Rank ${placeOf(e.value)}',
                              categoryOf(e.value),
                              if (!isPublished(e.value)) 'Unpublished',
                            ].join(' • '),
                            avatarText: '${placeOf(e.value)}',
                          )),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}