import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class SponsorshipListScreen extends ConsumerStatefulWidget {
  const SponsorshipListScreen({super.key});

  @override
  ConsumerState<SponsorshipListScreen> createState() => _SponsorshipListScreenState();
}

class _SponsorshipListScreenState extends ConsumerState<SponsorshipListScreen> {
  final List<String> _filters = ['All Sports', 'Football', 'Basketball', 'Athletics', 'Swimming'];
  String _selectedFilter = 'All Sports';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(sponsorshipsProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sponsorshipsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Sponsorships'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: SportXShadows.e1,
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      icon: Icon(LucideIcons.search, size: 20, color: AppColors.textSecondary),
                      hintText: 'Search sponsorships...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      return SportXChip(
                        label: filter,
                        selected: filter == _selectedFilter,
                        onTap: () => setState(() => _selectedFilter = filter),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: SectionHeader(title: 'Available Sponsorships'),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(sponsorshipsProvider.notifier).refresh(),
              child: state.isLoading && state.items.isEmpty
                  ? const GenericListSkeleton()
                  : state.items.isEmpty
                      ? const Center(child: Text('No sponsorships found'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: state.items.length,
                          itemBuilder: (context, i) {
                            final item = state.items[i];
                            final deadline = item.applicationDeadline;
                            final daysLeft = deadline?.difference(DateTime.now()).inDays;
                            final isSoon = daysLeft != null && daysLeft <= 30;
                            final deadlineLabel = deadline != null
                                ? 'Deadline: ${deadline.day}/${deadline.month}/${deadline.year}'
                                : null;

                            return GestureDetector(
                              onTap: () => context.push('/sponsorship-detail/${item.id}'),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: SportXShadows.e1,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: item.sponsorLogoUrl != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(14),
                                                  child: Image.network(
                                                    item.sponsorLogoUrl!,
                                                    width: 48,
                                                    height: 48,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, _, _) => const Icon(
                                                      LucideIcons.star,
                                                      color: AppColors.primary,
                                                      size: 24,
                                                    ),
                                                  ),
                                                )
                                              : const Icon(
                                                  LucideIcons.star,
                                                  color: AppColors.primary,
                                                  size: 24,
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${item.sponsorName ?? 'Sponsor'} • ${item.sport?.name ?? 'All Sports'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item.description != null) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        item.description!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        if (item.amountLabel != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.successLight,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              item.amountLabel!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.success,
                                              ),
                                            ),
                                          ),
                                        if (item.benefits != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.successLight,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              item.benefits!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.success,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (deadlineLabel != null) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSoon ? AppColors.yellowTint : AppColors.errorLight,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          deadlineLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isSoon ? AppColors.warnText : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}