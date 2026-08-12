import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/search/presentation/providers/search_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    ref.read(searchProvider.notifier).search(q);
    context.push('/universal-search');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final trending = ref.watch(trendingSearchesProvider);
    final recent = state.recentSearches;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: _runSearch,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Search academies, coaches, trials...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
            prefixIcon: Icon(LucideIcons.search, color: AppColors.textSecondary),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recent.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Searches',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () => ref.read(searchProvider.notifier).clearRecentSearches(),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...recent.map((q) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(LucideIcons.history, color: AppColors.textSecondary),
                    title: Text(q),
                    onTap: () {
                      _controller.text = q;
                      _runSearch(q);
                    },
                  )),
              const SizedBox(height: 16),
            ],
            Text('Trending', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trending
                  .map((label) => ActionChip(
                        label: Text(label),
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        onPressed: () {
                          _controller.text = label;
                          _runSearch(label);
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
