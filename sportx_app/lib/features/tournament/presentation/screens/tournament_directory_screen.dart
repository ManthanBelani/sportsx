import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/presentation/widgets/async_state_view.dart';
import 'package:sportx_app/shared/presentation/widgets/directory_list_template.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

class TournamentDirectoryScreen extends ConsumerWidget {
  const TournamentDirectoryScreen({super.key});

  String _meta(Tournament t) {
    if (t.startDate != null && t.endDate != null) {
      final s = t.startDate!, e = t.endDate!;
      return '${s.day}/${s.month}–${e.day}/${e.month}/${e.year}';
    }
    if (t.startDate != null) {
      return '${t.startDate!.day}/${t.startDate!.month}/${t.startDate!.year}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tournamentsProvider);

    return DirectoryStateView<Tournament>(
      state: state,
      title: 'Tournaments',
      onRetry: () => ref.read(tournamentsProvider.notifier).refresh(),
      dataBuilder: (items) => DirectoryListTemplate(
        title: 'Tournaments',
        defaultIcon: LucideIcons.trophy,
        items: items
            .map((t) => DirectoryItem(
                  id: t.id.toString(),
                  title: t.title,
                  subtitle: [t.venue, t.city?.name].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                  meta: _meta(t),
                ))
            .toList(),
        onFilterTap: () => context.push('/search-filter'),
        onItemTap: (item) => context.push('/tournament-detail/${item.id}'),
        onLoadMore: () => ref.read(tournamentsProvider.notifier).loadMore(),
      ),
    );
  }
}
