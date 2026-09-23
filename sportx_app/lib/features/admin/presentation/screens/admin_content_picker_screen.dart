import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

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
    int count(String type) => pickers.where((p) => p.type == type).fold(0, (s, p) => s + p.total);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text('Content Management',
            style: GoogleFonts.sora(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.ink), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _categories
            .map((c) => _buildCategoryTile(context, c.$1, c.$2, c.$3, '${count(c.$1)}'))
            .toList(),
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, String type, String name, IconData icon, String count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: SportXShadows.e1,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.yellowTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 20),
        ),
        title: Text(name,
            style: GoogleFonts.sora(
                fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.borderSoft),
                  borderRadius: BorderRadius.circular(999)),
              child: Text(count,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, color: AppColors.ink)),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, color: AppColors.textTertiary),
          ],
        ),
        onTap: () => context.push('/admin-content-list/$type'),
      ),
    );
  }
}
