import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/directory_list_template.dart';

class TournamentDirectoryScreen extends StatelessWidget {
  const TournamentDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dummyItems = List.generate(
      4,
      (index) => DirectoryItem(
        id: 'tourney_$index',
        title: 'U-16 State Cup ${index + 1}',
        subtitle: 'Sardar Patel Stadium',
        meta: 'Aug 15–20',
        rating: null,
        thumbnailUrl: null,
      ),
    );

    return DirectoryListTemplate(
      title: 'Tournaments',
      defaultIcon: LucideIcons.trophy,
      items: dummyItems,
      onFilterTap: () {
        context.push('/search-filter');
      },
      onItemTap: (item) => context.push('/tournament-detail/${item.id}'),
      onLoadMore: () {},
    );
  }
}
