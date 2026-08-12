import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class ScholarshipListScreen extends ConsumerStatefulWidget {
  const ScholarshipListScreen({super.key});

  @override
  ConsumerState<ScholarshipListScreen> createState() => _ScholarshipListScreenState();
}

class _ScholarshipListScreenState extends ConsumerState<ScholarshipListScreen> {
  final List<String> _filters = ['All Sports', 'Football', 'Basketball', 'Athletics', 'Swimming'];
  String _selectedFilter = 'All Sports';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(scholarshipsProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scholarshipsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Scholarships', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filters
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      icon: Icon(LucideIcons.search, size: 20, color: AppColors.textSecondary),
                      hintText: 'Search scholarships...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filter Chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isActive = filter == _selectedFilter;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary : AppColors.background,
                            border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isActive ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('Available Scholarships', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(scholarshipsProvider.notifier).refresh(),
              child: state.isLoading && state.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty
                      ? const Center(child: Text('No scholarships found'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: state.items.length,
                          itemBuilder: (context, i) {
                            final item = state.items[i];
                            // Mocking images and deadlines for UI completeness based on HTML
                            final imageUrl = 'https://images.unsplash.com/photo-${1535131749006 + i}?w=160&h=160&fit=crop';
                            final isSoon = i % 2 != 0;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 80,
                                        height: 80,
                                        color: AppColors.border,
                                        child: const Icon(LucideIcons.image, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title ?? 'Scholarship',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.sponsorName ?? 'Sponsor'} • ${item.sport?.name ?? 'All Sports'}',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            if (item.amount != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFd1fae5),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '₹${item.amount!.toStringAsFixed(0)}',
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF065f46)),
                                                ),
                                              ),
                                            if (item.amount != null) const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isSoon ? const Color(0xFFfef3c7) : const Color(0xFFfee2e2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isSoon ? 'Deadline: Jan 10' : 'Deadline: Dec 15',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSoon ? const Color(0xFF92400e) : const Color(0xFFdc2626),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
