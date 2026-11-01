import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/date_format_utils.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/presentation/widgets/async_state_view.dart';
import 'package:sportx_app/shared/presentation/widgets/directory_list_template.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

class TournamentDirectoryScreen extends ConsumerWidget {
  const TournamentDirectoryScreen({super.key});

  String _meta(Tournament t) {
    if (t.startDate != null && t.endDate != null) {
      final s = t.startDate!, e = t.endDate!;
      if (s.year == e.year && s.month == e.month && s.day == e.day) {
        return DateFormatUtils.formatDdMmYyyy(s);
      }
      return '${DateFormatUtils.formatDdMmYyyy(s)} – ${DateFormatUtils.formatDdMmYyyy(e)}';
    }
    if (t.startDate != null) {
      return DateFormatUtils.formatDdMmYyyy(t.startDate);
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
