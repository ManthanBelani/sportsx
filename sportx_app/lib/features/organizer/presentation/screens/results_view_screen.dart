import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class ResultsViewScreen extends ConsumerWidget {
  final String tournamentId;
  final String title;
  const ResultsViewScreen({super.key, required this.tournamentId, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tournamentResultsProvider(tournamentId));
    final results = async.valueOrNull ?? [];

    Widget medalFor(int index, String label) {
      final emoji = ['🥇', '🥈', '🥉'][index];
      final entry = index < results.length ? results[index] : null;
      final name = (entry?['winner'] ?? entry?['team_name'] ?? entry?['name'] ?? '—').toString();
      return Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(name, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('$title — Results',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(tournamentResultsProvider(tournamentId)),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$e', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => ref.invalidate(tournamentResultsProvider(tournamentId)), child: const Text('Retry')),
            ]),
          ),
          data: (_) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: results.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Center(child: Text('Results not published yet', style: TextStyle(color: AppColors.textSecondary))),
                  )
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          medalFor(0, 'Winner'),
                          medalFor(1, 'Runner-up'),
                          medalFor(2, '3rd Place'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Full Standings', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const SizedBox(height: 8),
                      ...results.asMap().entries.map((e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(child: Text('${e.key + 1}')),
                            title: Text((e.value['winner'] ?? e.value['team_name'] ?? e.value['name'] ?? '').toString()),
                          )),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
