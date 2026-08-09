import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search academies, coaches...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Searches', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.history, color: Colors.grey),
              title: Text('Cricket academies Ahmedabad'),
              dense: true,
            ),
            const ListTile(
              leading: Icon(Icons.history, color: Colors.grey),
              title: Text('Football trials under-14'),
              dense: true,
            ),
            const SizedBox(height: 24),
            Text('Trending', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _TrendingChip(label: 'Cricket'),
                _TrendingChip(label: 'Football'),
                _TrendingChip(label: 'Athletics'),
                _TrendingChip(label: 'Badminton'),
                _TrendingChip(label: 'Swimming'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingChip extends StatelessWidget {
  final String label;
  const _TrendingChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () {},
      backgroundColor: Colors.grey[200],
    );
  }
}
