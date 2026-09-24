import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class SportsVenueListScreen extends ConsumerWidget {
  const SportsVenueListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sportsVenuesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SportXTopBar(
        title: 'Sports Venues',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(sportsVenuesProvider.notifier).refresh(),
        child: state.isLoading && state.items.isEmpty
            ? const GenericListSkeleton()
            : state.items.isEmpty
                ? const Center(child: Text('No venues found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (context, i) {
                      final item = state.items[i];
                      return EntityRow(
                        title: item.name,
                        subtitle: item.city?.name ?? '',
                        avatarText: item.name.isNotEmpty ? item.name[0].toUpperCase() : 'V',
                        onTap: () => context.push('/sports-venue-detail/${item.id}'),
                        trailing: item.bookingAvailable == true
                            ? const StatusPill(label: 'Bookable', kind: PillKind.ok)
                            : const Icon(LucideIcons.chevronRight,
                                color: Color(0xFFC9CDD3), size: 20),
                      );
                    },
                  ),
      ),
    );
  }
}
