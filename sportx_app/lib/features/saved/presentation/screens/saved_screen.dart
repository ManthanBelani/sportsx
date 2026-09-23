import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/saved/presentation/providers/saved_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['All', 'Academies', 'Coaches', 'Trials', 'Tournaments', 'Scholarships', 'Sponsorships'];

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
        return 'coach';
      case 3:
        return 'trial';
      case 4:
        return 'tournament';
      case 5:
        return 'scholarship';
      case 6:
        return 'sponsorship';
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
        return '/sponsorship-detail/${item.itemId}';
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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Saved',
            style: GoogleFonts.sora(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: state.isLoading
          ? RefreshIndicator(
              onRefresh: () => ref.read(savedProvider.notifier).load(),
              child: const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: GenericListSkeleton(),
              ),
            )
          : state.error != null && state.items.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => ref.read(savedProvider.notifier).load(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(state.error!, style: TextStyle(color: AppColors.textSecondary)),
                            SizedBox(height: 12),
                            PrimaryButton(
                              label: 'Retry',
                              onPressed: () => ref.read(savedProvider.notifier).load(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : state.items.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () => ref.read(savedProvider.notifier).load(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: const Center(
                            child: Text('No saved items yet',
                                style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        ),
                      ),
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
      return RefreshIndicator(
        onRefresh: () => ref.read(savedProvider.notifier).load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: const Center(
              child: Text('Nothing here yet', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(savedProvider.notifier).load(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          final initial =
              item.title.isNotEmpty ? item.title[0].toUpperCase() : 'S';
          return EntityRow(
            title: item.title,
            subtitle: item.subtitle,
            avatarText: initial,
            onTap: () => context.push(_routeFor(item)),
            trailing: IconButton(
              icon: const Icon(LucideIcons.trash2,
                  color: AppColors.textSecondary, size: 20),
              onPressed: () => ref.read(savedProvider.notifier).remove(item),
            ),
          );
        },
      ),
    );
  }
}
