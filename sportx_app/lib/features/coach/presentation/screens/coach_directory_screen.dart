import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/directory_list_template.dart';

class CoachDirectoryScreen extends StatelessWidget {
  const CoachDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dummyItems = List.generate(
      8,
      (index) => DirectoryItem(
        id: 'coach_$index',
        title: 'Rahul Mehta ${index + 1}',
        subtitle: 'Cricket · 8 yrs exp',
        meta: '₹800/session',
        rating: '4.9 (89)',
        thumbnailUrl: null, // Use default icon
      ),
    );

    return DirectoryListTemplate(
      title: 'Coaches',
      defaultIcon: LucideIcons.user,
      items: dummyItems,
      onFilterTap: () {
        context.push('/search-filter');
      },
      onItemTap: (item) => context.push('/coach-profile-detail/${item.id}'),
      onLoadMore: () {},
    );
  }
}
