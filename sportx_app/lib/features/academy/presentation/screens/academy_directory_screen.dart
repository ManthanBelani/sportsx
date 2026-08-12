import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/presentation/widgets/async_state_view.dart';
import 'package:sportx_app/shared/presentation/widgets/directory_list_template.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

class AcademyDirectoryScreen extends ConsumerWidget {
  const AcademyDirectoryScreen({super.key});

  String _price(Academy a) {
    if (a.monthlyRate != null) return '₹${a.monthlyRate!.toStringAsFixed(0)}/mo';
    if (a.hourlyRate != null) return '₹${a.hourlyRate!.toStringAsFixed(0)}/hr';
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(academiesProvider);

    return DirectoryStateView<Academy>(
      state: state,
      title: 'Academies',
      onRetry: () => ref.read(academiesProvider.notifier).refresh(),
      dataBuilder: (items) => DirectoryListTemplate(
        title: 'Academies',
        defaultIcon: LucideIcons.building2,
        items: items
            .map((a) => DirectoryItem(
                  id: a.id.toString(),
                  title: a.name,
                  subtitle: [a.sport?.name, a.city?.name].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                  meta: _price(a),
                  thumbnailUrl: a.logoUrl,
                ))
            .toList(),
        onFilterTap: () => context.push('/search-filter'),
        onItemTap: (item) => context.push('/academy-detail/${item.id}'),
        onLoadMore: () => ref.read(academiesProvider.notifier).loadMore(),
      ),
    );
  }
}
