import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class AdminContentListScreen extends ConsumerStatefulWidget {
  final String category;
  const AdminContentListScreen({super.key, required this.category});

  @override
  ConsumerState<AdminContentListScreen> createState() => _AdminContentListScreenState();
}

class _AdminContentListScreenState extends ConsumerState<AdminContentListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).loadContentList(widget.category));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final displayName = widget.category[0].toUpperCase() + widget.category.substring(1);
    final items = state.contentList;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(displayName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => ref.read(adminProvider.notifier).loadContentList(widget.category, q: v.isEmpty ? null : v),
              decoration: InputDecoration(
                hintText: 'Search $displayName...',
                prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
          ),
          Expanded(
            child: state.isLoading && items.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : items.isEmpty
                    ? const Center(child: Text('No items', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i] as Map<String, dynamic>;
                          final title = (item['title'] ?? item['name'] ?? item['full_name'] ?? 'Item #$i').toString();
                          final status = (item['status'] ?? 'draft').toString();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Text(status, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
