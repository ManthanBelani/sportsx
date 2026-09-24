import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/providers.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// v2 opportunities.html — unified feed: All / Trials / Tournaments /
/// Scholarships / Sponsorships tabs over the existing directory providers.
/// Read-only aggregator: same providers, same detail routes.
class OpportunitiesScreen extends ConsumerStatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  ConsumerState<OpportunitiesScreen> createState() =>
      _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends ConsumerState<OpportunitiesScreen> {
  String _tab = 'All';
  static const _tabs = [
    'All',
    'Trials',
    'Tournaments',
    'Scholarships',
    'Sponsorships'
  ];

  @override
  Widget build(BuildContext context) {
    final trials = ref.watch(trialsProvider);
    final tournaments = ref.watch(tournamentsProvider);
    final scholarships = ref.watch(scholarshipsProvider);
    final sponsorships = ref.watch(sponsorshipsProvider);
    final loading = trials.isLoading ||
        tournaments.isLoading ||
        scholarships.isLoading ||
        sponsorships.isLoading;

    Future<void> onRefresh() async {
      await Future.wait([
        ref.read(trialsProvider.notifier).refresh(),
        ref.read(tournamentsProvider.notifier).refresh(),
        ref.read(scholarshipsProvider.notifier).refresh(),
        ref.read(sponsorshipsProvider.notifier).refresh(),
      ]);
    }

    final cards = <Widget>[];
    if (_tab == 'All' || _tab == 'Trials') {
      for (final t in trials.items.take(_tab == 'All' ? 3 : 20)) {
        cards.add(OppCard(
          title: t.title,
          org: t.venue ?? 'Trial',
          meta: [
            if (t.trialDate != null)
              (
                icon: LucideIcons.calendar,
                text: _shortDate(t.trialDate!)
              ),
            if ((t.venue ?? '').isNotEmpty)
              (icon: LucideIcons.mapPin, text: t.venue!),
            if ((t.ageGroupLabel ?? '').isNotEmpty)
              (icon: LucideIcons.user, text: t.ageGroupLabel!),
          ],
          onTap: () => context.push('/trial-detail/${t.id}'),
        ));
      }
    }
    if (_tab == 'All' || _tab == 'Tournaments') {
      for (final t in tournaments.items.take(_tab == 'All' ? 3 : 20)) {
        cards.add(OppCard(
          title: t.title,
          org: t.venue ?? 'Tournament',
          meta: [
            if (t.startDate != null)
              (
                icon: LucideIcons.calendar,
                text: _shortDate(t.startDate!)
              ),
            if ((t.venue ?? '').isNotEmpty)
              (icon: LucideIcons.mapPin, text: t.venue!),
          ],
          onTap: () => context.push('/tournament-detail/${t.id}'),
        ));
      }
    }
    if (_tab == 'All' || _tab == 'Scholarships') {
      for (final s in scholarships.items.take(_tab == 'All' ? 3 : 20)) {
        cards.add(OppCard(
          title: s.title,
          org: s.sponsorName ?? 'Scholarship',
          meta: [
            if ((s.amountLabel ?? '').isNotEmpty)
              (icon: LucideIcons.wallet, text: s.amountLabel!),
            if (s.applicationDeadline != null)
              (
                icon: LucideIcons.clock,
                text: _shortDate(s.applicationDeadline!)
              ),
          ],
          onTap: () => context.push('/scholarship-detail/${s.id}'),
        ));
      }
    }
    if (_tab == 'All' || _tab == 'Sponsorships') {
      for (final s in sponsorships.items.take(_tab == 'All' ? 3 : 20)) {
        cards.add(OppCard(
          title: s.title,
          org: s.sponsorName ?? 'Sponsorship',
          meta: [
            if ((s.amountLabel ?? '').isNotEmpty)
              (icon: LucideIcons.wallet, text: s.amountLabel!),
            if ((s.sponsorshipType ?? '').isNotEmpty)
              (icon: LucideIcons.briefcase, text: s.sponsorshipType!),
          ],
          onTap: () => context.push('/sponsorship-detail/${s.id}'),
        ));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Opportunities',
            style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        actions: [
          SportXIconButton(
              icon: LucideIcons.bell, onTap: () => context.push('/notifications')),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.yellowDeep,
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                    child: SportXSearchBar(
                        hint: 'Search trials, tournaments...',
                        onTap: () => context.push('/universal-search'))),
                const SizedBox(width: 10),
                SportXIconButton(
                    icon: LucideIcons.slidersHorizontal,
                    onTap: () => context.push('/search-filter')),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final t in _tabs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SportXChip(
                          label: t,
                          selected: _tab == t,
                          onTap: () => setState(() => _tab = t)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (loading && cards.isEmpty)
              const GenericListSkeleton()
            else if (cards.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                    child: Text('No opportunities found',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary))),
              )
            else
              ...cards,
          ],
        ),
      ),
    );
  }

  static String _shortDate(DateTime d) =>
      '${d.day} ${_month(d.month)} ${d.year}';

  static String _month(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];
}
