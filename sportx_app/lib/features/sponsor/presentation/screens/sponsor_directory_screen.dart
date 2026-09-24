import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// v2 sponsor-directory.html — athlete-facing sponsor directory:
/// XSports India (Kit · ₹50k · U-19), FuelFit (Nutrition · monthly · Active).
/// Same sponsorshipsProvider as the coach directory; tapping opens the
/// existing sponsorship detail.
class SponsorDirectoryScreen extends ConsumerStatefulWidget {
  const SponsorDirectoryScreen({super.key});

  @override
  ConsumerState<SponsorDirectoryScreen> createState() =>
      _SponsorDirectoryScreenState();
}

class _SponsorDirectoryScreenState
    extends ConsumerState<SponsorDirectoryScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sponsorshipsProvider);
    final q = _query.toLowerCase();
    final items = state.items.where((s) {
      if (q.isEmpty) return true;
      return s.title.toLowerCase().contains(q) ||
          (s.sponsorName ?? '').toLowerCase().contains(q) ||
          (s.sponsorshipType ?? '').toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.ink),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text('Sponsors',
            style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      ),
      body: RefreshIndicator(
        color: AppColors.yellowDeep,
        onRefresh: () => ref.read(sponsorshipsProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border.all(color: AppColors.border, width: 1.5),
                borderRadius: BorderRadius.circular(14),
                boxShadow: SportXShadows.e1,
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.search,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (v) =>
                          setState(() => _query = v.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Search sponsors...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.ink),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                      child: const Icon(LucideIcons.x,
                          size: 16, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
              child: Text('${items.length} sponsors found',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
            if (state.isLoading && items.isEmpty)
              const GenericListSkeleton()
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                    child: Text('No sponsors found',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary))),
              )
            else
              for (final s in items)
                EntityRow(
                  title: s.sponsorName ?? s.title,
                  subtitle: [
                    if ((s.sponsorshipType ?? '').isNotEmpty)
                      s.sponsorshipType!,
                    if ((s.amountLabel ?? '').isNotEmpty)
                      s.amountLabel!,
                    s.status
                  ].join(' · '),
                  avatarText: (s.sponsorName ?? s.title).isNotEmpty
                      ? (s.sponsorName ?? s.title)[0].toUpperCase()
                      : 'S',
                  onTap: () => context.push('/sponsorship-detail/${s.id}'),
                ),
          ],
        ),
      ),
    );
  }
}
