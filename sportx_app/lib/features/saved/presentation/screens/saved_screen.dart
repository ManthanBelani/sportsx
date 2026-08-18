import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/saved/presentation/providers/saved_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['All', 'Academies', 'Trials', 'Tournaments', 'Scholarships'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    Future.microtask(() => ref.read(savedProvider.notifier).load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _typeForTab(int index) {
    switch (index) {
      case 1:
        return 'academy';
      case 2:
        return 'trial';
      case 3:
        return 'tournament';
      case 4:
        return 'scholarship';
      default:
        return null;
    }
  }

  String _routeFor(SavedItem item) {
    switch (item.type) {
      case 'academy':
      case 'academies':
        return '/academy-detail/${item.itemId}';
      case 'coach':
      case 'coach_profile':
      case 'coaches':
        return '/coach-detail/${item.itemId}';
      case 'trial':
      case 'trials':
        return '/trial-detail/${item.itemId}';
      case 'tournament':
      case 'tournaments':
        return '/tournament-detail/${item.itemId}';
      case 'scholarship':
      case 'scholarships':
        return '/scholarship-detail/${item.itemId}';
      case 'sponsorship':
      case 'sponsorships':
      case 'sponsor':
        return '/sponsor-pitch/${item.itemId}';
      case 'sports_venue':
      case 'sportsvenue':
        return '/sports-venues';
      default:
        return '/universal-search';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Saved',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.error != null && state.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.error!, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(savedProvider.notifier).load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.items.isEmpty
                  ? const Center(
                      child: Text('No saved items yet',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: List.generate(_tabs.length, (i) {
                        final filter = _typeForTab(i);
                        final items = filter == null
                            ? state.items
                            : state.items.where((it) => it.type.contains(filter)).toList();
                        return _buildList(items);
                      }),
                    ),
    );
  }

  Widget _buildList(List<SavedItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Nothing here yet', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(savedProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = items[i];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.heart, color: Colors.red),
            title: Text(item.title,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            subtitle: Text(item.subtitle, style: const TextStyle(color: AppColors.textSecondary)),
            trailing: IconButton(
              icon: const Icon(LucideIcons.trash2, color: AppColors.textSecondary, size: 20),
              onPressed: () => ref.read(savedProvider.notifier).remove(item),
            ),
            onTap: () => context.push(_routeFor(item)),
          );
        },
      ),
    );
  }
}
