import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class AdminContentPickerScreen extends ConsumerStatefulWidget {
  const AdminContentPickerScreen({super.key});

  @override
  ConsumerState<AdminContentPickerScreen> createState() => _AdminContentPickerScreenState();
}

class _AdminContentPickerScreenState extends ConsumerState<AdminContentPickerScreen> {
  static const _categories = [
    ('academies', 'Academies', LucideIcons.building2),
    ('coaches', 'Coaches', LucideIcons.user),
    ('trials', 'Trials', LucideIcons.circleDot),
    ('tournaments', 'Tournaments', LucideIcons.trophy),
    ('scholarships', 'Scholarships', LucideIcons.graduationCap),
    ('sponsorships', 'Sponsorships', LucideIcons.award),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).loadContentPicker());
  }

  @override
  Widget build(BuildContext context) {
    final pickers = ref.watch(adminProvider).contentPicker;
    int _count(String type) => pickers.where((p) => p.type == type).fold(0, (s, p) => s + p.total);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Content Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _categories
            .map((c) => _buildCategoryTile(context, c.$1, c.$2, c.$3, '${_count(c.$1)}'))
            .toList(),
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, String type, String name, IconData icon, String count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
              child: Text(count, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
        onTap: () => context.push('/admin-content-list/$type'),
      ),
    );
  }
}
