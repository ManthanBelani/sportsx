import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/presentation/widgets/async_state_view.dart';
import 'package:sportx_app/shared/presentation/widgets/directory_list_template.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

class TrialDirectoryScreen extends ConsumerWidget {
  const TrialDirectoryScreen({super.key});

  String _meta(Trial t) {
    final parts = <String>[];
    if (t.trialDate != null) {
      parts.add('${t.trialDate!.day}/${t.trialDate!.month}/${t.trialDate!.year}');
    }
    if (t.registrationFee != null) parts.add('₹${t.registrationFee!.toStringAsFixed(0)}');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trialsProvider);

    return DirectoryStateView<Trial>(
      state: state,
      title: 'Trials',
      onRetry: () => ref.read(trialsProvider.notifier).refresh(),
      dataBuilder: (items) => DirectoryListTemplate(
        title: 'Trials',
        defaultIcon: LucideIcons.circleDot,
        items: items
            .map((t) => DirectoryItem(
                  id: t.id.toString(),
                  title: t.title,
                  subtitle: [t.venue, t.city?.name].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                  meta: _meta(t),
                ))
            .toList(),
        onFilterTap: () => context.push('/search-filter'),
        onItemTap: (item) => context.push('/trial-detail/${item.id}'),
        onLoadMore: () => ref.read(trialsProvider.notifier).loadMore(),
      ),
    );
  }
}
