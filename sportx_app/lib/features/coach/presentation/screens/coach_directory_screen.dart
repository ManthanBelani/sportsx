import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/presentation/widgets/async_state_view.dart';
import 'package:sportx_app/shared/presentation/widgets/directory_list_template.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

class CoachDirectoryScreen extends ConsumerWidget {
  const CoachDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coachesProvider);

    return DirectoryStateView<Coach>(
      state: state,
      title: 'Coaches',
      onRetry: () => ref.read(coachesProvider.notifier).refresh(),
      dataBuilder: (items) => DirectoryListTemplate(
        title: 'Coaches',
        defaultIcon: LucideIcons.user,
        items: items
            .map((c) => DirectoryItem(
                  id: c.id.toString(),
                  title: c.fullName,
                  subtitle: [
                    c.sport?.name,
                    if (c.experience != null) '${c.experience} yrs exp',
                  ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                  meta: c.hourlyRate != null ? '₹${c.hourlyRate!.toStringAsFixed(0)}/session' : '',
                  thumbnailUrl: c.profilePhotoUrl,
                ))
            .toList(),
        onFilterTap: () => context.push('/search-filter'),
        onItemTap: (item) => context.push('/coach-profile-detail/${item.id}'),
        onLoadMore: () => ref.read(coachesProvider.notifier).loadMore(),
      ),
    );
  }
}
