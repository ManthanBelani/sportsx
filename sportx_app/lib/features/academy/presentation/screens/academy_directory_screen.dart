import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/directory_list_template.dart';

class AcademyDirectoryScreen extends StatelessWidget {
  const AcademyDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dummyItems = List.generate(
      10,
      (index) => DirectoryItem(
        id: 'academy_$index',
        title: 'Elite Cricket Academy ${index + 1}',
        subtitle: 'Cricket · Ahmedabad',
        meta: '₹2,000 – ₹5,000/mo',
        rating: '4.8 (124)',
        thumbnailUrl: null, // Use default icon
      ),
    );

    return DirectoryListTemplate(
      title: 'Academies',
      defaultIcon: LucideIcons.building2,
      items: dummyItems,
      onFilterTap: () {
        context.push('/search-filter');
      },
      onItemTap: (item) {
        context.push('/academy-detail/${item.id}');
      },
      onLoadMore: () {},
    );
  }
}
