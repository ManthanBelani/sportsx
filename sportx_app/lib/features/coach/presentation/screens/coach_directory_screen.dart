import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/home_kit.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// v3.4: the coaches list uses the same list-row design as the athlete list
/// (PersonRowCard). Tapping a row opens the coach's profile (the shared
/// ViewProfileScreen).
class CoachDirectoryScreen extends ConsumerStatefulWidget {
  const CoachDirectoryScreen({super.key});

  @override
  ConsumerState<CoachDirectoryScreen> createState() => _CoachDirectoryScreenState();
}

class _CoachDirectoryScreenState extends ConsumerState<CoachDirectoryScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachesProvider);
    final query = _search.text.trim().toLowerCase();
    final items = query.isEmpty
        ? state.items
        : state.items
            .where((c) =>
                c.fullName.toLowerCase().contains(query) ||
                (c.specialization ?? '').toLowerCase().contains(query) ||
                (c.sport?.name ?? '').toLowerCase().contains(query))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Find Coaches',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search coaches by name…',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              suffixIcon: IconButton(icon: const Icon(LucideIcons.x, size: 16), onPressed: () {
                _search.clear();
                setState(() {});
              }),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        Expanded(
          child: state.isLoading && state.items.isEmpty
              ? const GenericListSkeleton()
              : state.error != null && state.items.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.border),
                      const SizedBox(height: 12),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text(state.error!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center)),
                      const SizedBox(height: 12),
                      PrimaryButton(label: 'Retry', onPressed: () => ref.read(coachesProvider.notifier).refresh()),
                    ]))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(coachesProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        itemCount: items.length + (state.hasMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 0),
                        itemBuilder: (context, i) {
                          if (i >= items.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: OutlinedButton(
                                onPressed: state.isLoading ? null : () => ref.read(coachesProvider.notifier).loadMore(),
                                child: const Text('Load more'),
                              ),
                            );
                          }
                          return _personRow(items[i]);
                        },
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _personRow(Coach c) {
    final role = [
      c.sport?.name,
      if (c.experience != null) '${c.experience} yrs exp',
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    return PersonRowCard(
      name: c.fullName,
      role: role.isNotEmpty ? role : 'Coach',
      city: c.city?.name,
      photoUrl: c.profilePhotoUrl,
      rating: c.avgRating ?? c.rating ?? 0,
      ctaLabel: 'View',
      onTap: () => context.push(
        '/view-profile',
        extra: {'type': 'coach', 'id': c.id.toString()},
      ),
    );
  }
}
