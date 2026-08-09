import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/directory_list_template.dart';

class TrialDirectoryScreen extends StatelessWidget {
  const TrialDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dummyItems = List.generate(
      6,
      (index) => DirectoryItem(
        id: 'trial_$index',
        title: 'U-14 Cricket Trials ${index + 1}',
        subtitle: 'Sardar Patel Stadium',
        meta: 'Aug 15 · ₹200',
        rating: null,
        thumbnailUrl: null,
      ),
    );

    return DirectoryListTemplate(
      title: 'Trials',
      defaultIcon: LucideIcons.circleDot,
      items: dummyItems,
      onFilterTap: () {
        context.push('/search-filter');
      },
      onItemTap: (item) => context.push('/trial-detail/${item.id}'),
      onLoadMore: () {},
    );
  }
}
