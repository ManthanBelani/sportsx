import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text(displayName,
            style: GoogleFonts.sora(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.ink), onPressed: () => context.pop()),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: state.isLoading && items.isEmpty
                ? const GenericListSkeleton()
                : items.isEmpty
                    ? Center(child: Text('No items', style: GoogleFonts.inter(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i] as Map<String, dynamic>;
                          final title = (item['title'] ?? item['name'] ?? item['full_name'] ?? 'Item #$i').toString();
                          final status = (item['status'] ?? 'draft').toString();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: SportXShadows.e1,
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.ink))),
                                StatusPill(
                                  label: status,
                                  kind: status == 'published' || status == 'approved'
                                      ? PillKind.ok
                                      : status == 'pending'
                                          ? PillKind.pending
                                          : PillKind.draft,
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