import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/home_kit.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// OR.2 Organizer dashboard — chevron greet card, Upcoming Events (with a
/// registration fill bar), kpi-grid, action chips row and feed — per design.
class OrganizerDashboardScreen extends ConsumerWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final trials = ref.watch(myTrialsProvider);
    final tournaments = ref.watch(myTournamentsProvider);
    final analytics = ref.watch(organizerAnalyticsProvider);

    final upcoming = <_EventRow>[
      ...tournaments.items.take(3).map((t) => _EventRow(
            title: t.title,
            date: t.startDate,
            venue: t.venue ?? '',
            registered: t.filledSpots?.toString(),
            total: t.totalSpots,
            onTap: () => context.push('/tournament-detail/${t.id}'),
          )),
      ...trials.items.take(3).map((t) => _EventRow(
            title: t.title,
            date: t.trialDate,
            venue: t.venue ?? '',
            registered: t.filledSpots?.toString(),
            total: t.totalSpots,
            onTap: () => context.push('/trial-detail/${t.id}'),
          )),
    ]..sort((a, b) => (a.date ?? DateTime(9999)).compareTo(b.date ?? DateTime(9999)));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.yellowDeep,
        onRefresh: () async {
          await ref.read(myTrialsProvider.notifier).refresh();
          await ref.read(myTournamentsProvider.notifier).refresh();
          ref.invalidate(organizerAnalyticsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.96),
              pinned: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: 68,
              titleSpacing: 16,
              title: Row(
                children: const [
                  Expanded(child: SportXWordmark()),
                  HomeHeaderActions(),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GreetCardV3(
                    greeting: greetingFor(DateTime.now()),
                    name: 'Hi, ${user?.name ?? 'Organizer'}!',
                    avatarInitial: (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'O',
                    subtitle: '75% complete',
                    progress: 0.75,
                    chevron: true,
                    onTap: () => context.push('/organizer-profile'),
                  ),
                  const SizedBox(height: 10),
                  SectionHeadV3(
                      title: 'Upcoming Events',
                      actionText: 'View All',
                      onActionTap: () => context.push('/my-tournaments')),
                  if (upcoming.isEmpty)
                    emptyHint('No upcoming events — create your first trial or tournament.')
                  else
                    ...upcoming.take(3).map((e) => _EventCard(row: e)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Kpi(
                          value: analytics.maybeWhen(
                              data: (a) => '${a.totalTournaments + a.totalTrials}+',
                              orElse: () => '—'),
                          label: 'Events',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Kpi(
                          value: analytics.maybeWhen(
                              data: (a) =>
                                  '${a.totalRegistrations}',
                              orElse: () => '—'),
                          label: 'Participants',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        SportXChip(
                            label: 'Create Event',
                            icon: LucideIcons.plus,
                            onTap: () => context.go('/create')),
                        const SizedBox(width: 7),
                        SportXChip(
                            label: 'Registrations',
                            icon: LucideIcons.clipboardList,
                            onTap: () => context.push('/registration-management')),
                        const SizedBox(width: 7),
                        SportXChip(
                            label: 'Analytics',
                            icon: LucideIcons.chartLine,
                            onTap: () => context.push('/organizer-analytics')),
                        const SizedBox(width: 7),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const V3FeedPreview(),
                  const SizedBox(height: 96),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventRow {
  final String title;
  final DateTime? date;
  final String venue;
  final String? registered;
  final int? total;
  final VoidCallback onTap;
  const _EventRow({
    required this.title,
    required this.date,
    required this.venue,
    required this.registered,
    required this.total,
    required this.onTap,
  });
}

class _EventCard extends StatelessWidget {
  final _EventRow row;
  const _EventCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final t = row.total ?? 0;
    final r = int.tryParse(row.registered ?? '') ?? 0;
    final fill = t > 0 ? (r / t).clamp(0.0, 1.0) : 0.0;
    return GestureDetector(
      onTap: row.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(
                '${_fmtDate(row.date)} · ${row.venue.isNotEmpty ? row.venue : 'Venue'} · '
                '${row.registered ?? 0} registered · ${t > 0 ? '$t slots' : 'Open'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              height: 6,
              decoration: BoxDecoration(color: AppColors.borderSoft, borderRadius: BorderRadius.circular(99)),
              clipBehavior: Clip.antiAlias,
              child: FractionallySizedBox(
                widthFactor: fill,
                alignment: Alignment.centerLeft,
                child: Container(decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(99))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

String _fmtDate(DateTime? d) => d == null ? 'TBA' : '${_months[d.month - 1]} ${d.day}';

class _Kpi extends StatelessWidget {
  final String value;
  final String label;
  const _Kpi({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: SportXShadows.e1,
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
