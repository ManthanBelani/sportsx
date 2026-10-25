import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/features/organizer/presentation/widgets/organizer_kit.dart';
import 'package:sportx_app/features/trial/presentation/providers/unified_events_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/home_kit.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// OR.2 Organizer home — the design board's screen 1: completion greet card,
/// "Upcoming Events (Your Events)" with the featured event card, the 4-tile
/// stat row, the 4 quick action tiles and the feed switcher + post card.
class OrganizerDashboardScreen extends ConsumerWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final myEvents = ref.watch(myEventsProvider);
    final analytics = ref.watch(organizerAnalyticsProvider);
    final completion = ref.watch(organizerCompletionProvider).valueOrNull;
    final org = ref.watch(myOrganizerProvider).valueOrNull;

    final orgName = (org?['organization_name']?.toString() ?? '').isNotEmpty
        ? org!['organization_name'].toString()
        : (user?.name ?? 'Organizer');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Upcoming = published/active and not in the past. Trials and tournaments
    // come from the unified events endpoint, so the dashboard shows every
    // event the organizer runs.
    final upcoming =
        myEvents.events.where((e) {
          final status = e.status;
          if (status != 'published' && status != 'active') return false;
          final start = e.startDate;
          return start == null || !start.isBefore(today);
        }).toList()..sort(
          (a, b) => (a.startDate ?? DateTime(9999)).compareTo(
            b.startDate ?? DateTime(9999),
          ),
        );

    final featured = upcoming.isEmpty ? null : upcoming.first;

    final a = analytics.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.yellowDeep,
        onRefresh: () async {
          await ref.read(myEventsProvider.notifier).load();
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
                  // ── Completion greet card ────────────────────────────────
                  GreetCardV3(
                    greeting: greetingFor(DateTime.now()),
                    name: 'Hi, $orgName!',
                    avatarInitial: (orgName.trim().isNotEmpty)
                        ? orgName.trim()[0].toUpperCase()
                        : 'O',
                    subtitle: 'Complete your profile to reach more athletes',
                    progress: (completion ?? 0) / 100,
                    chevron: true,
                    onTap: () => context.push('/organizer-profile'),
                  ),
                  const SizedBox(height: 10),

                  // ── Upcoming events ─────────────────────────────────────
                  SectionHeadV3(
                    title: 'Upcoming Events (Your Events)',
                    actionText: 'View All',
                    onActionTap: () => context.push('/my-tournaments'),
                  ),
                  if (myEvents.isLoading && upcoming.isEmpty)
                    const _EventCardSkeleton()
                  else if (featured == null)
                    emptyHint(
                      'No upcoming events — create your first trial or tournament.',
                    )
                  else
                    OrgEventCard(
                      title: featured.name,
                      start: featured.startDate,
                      end: featured.endDate,
                      location: featured.locationLabel,
                      sportName: featured.sportName,
                      bannerUrl: featured.bannerUrl,
                      registrationsOpen: featured.registrationsOpen,
                      registeredCount: featured.registeredCount,
                      trailing: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          LucideIcons.moreVertical,
                          size: 15,
                          color: AppColors.textTertiary,
                        ),
                        onSelected: (v) {
                          switch (v) {
                            case 'manage':
                              // Tournaments open the organizer's Event
                              // Details & Management screen (design board
                              // screen 8); trials open their registrant
                              // management (approve/reject) screen.
                              context.push(
                                featured.isTournament
                                    ? '/organizer-event/${featured.id}'
                                    : '/registrant-list',
                                extra: {
                                  'id': featured.id,
                                  'title': featured.name,
                                },
                              );
                              break;
                            case 'registrations':
                              context.push(
                                featured.isTournament
                                    ? '/registration-management'
                                    : '/registrant-list',
                                extra: {
                                  'id': featured.id,
                                  'title': featured.name,
                                },
                              );
                              break;
                            case 'edit':
                              context.push('/edit-tournament/${featured.id}');
                              break;
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'manage',
                            child: Text('View event'),
                          ),
                          PopupMenuItem(
                            value: 'registrations',
                            child: Text('Registrations'),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit event'),
                          ),
                        ],
                      ),
                      onTap: () => context.push(
                        featured.isTournament
                            ? '/organizer-event/${featured.id}'
                            : '/registrant-list',
                        extra: {
                          'id': featured.id,
                          'title': featured.name,
                        },
                      ),
                    ),
                  if (upcoming.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          for (final e in upcoming.skip(1).take(2)) ...[
                            Expanded(
                              child: _MiniEventCard(
                                title: e.name,
                                date: e.startDate,
                                registered: e.registeredCount,
                                onTap: () => context.push(
                                  e.isTournament
                                      ? '/organizer-event/${e.id}'
                                      : '/registrant-list',
                                  extra: {
                                    'id': e.id,
                                    'title': e.name,
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 14),

                  // ── Stat row (Events · Participants · Views · Revenue) ───
                  // Board colours: gold / blue / red / green icons.
                  Row(
                    children: [
                      Expanded(
                        child: OrgStatTile(
                          value: a == null ? '—' : '${a.totalEvents}',
                          label: 'Events',
                          icon: LucideIcons.calendar,
                          iconColor: AppColors.warnText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OrgStatTile(
                          value: a == null
                              ? '—'
                              : '${compactIndianNumber(a.totalRegistrations)}+',
                          label: 'Participants',
                          icon: LucideIcons.users,
                          iconColor: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OrgStatTile(
                          value: a == null
                              ? '—'
                              : '${compactIndianNumber(a.views)}+',
                          label: 'Views',
                          icon: LucideIcons.eye,
                          iconColor: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OrgStatTile(
                          value: a == null
                              ? '—'
                              : '₹${compactIndianNumber(a.revenueEstimate)}',
                          label: 'Revenue',
                          icon: LucideIcons.chartLine,
                          iconColor: const Color(0xFF3FA55C),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Quick actions ───────────────────────────────────────
                  // IntrinsicHeight + stretch: every tile matches the tallest
                  // one, so the row stays even no matter how labels wrap.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: OrgQuickTile(
                            icon: LucideIcons.calendarPlus,
                            label: 'Create Event',
                            iconBg: AppColors.errorLight,
                            iconFg: AppColors.error,
                            onTap: () => context.go('/create'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OrgQuickTile(
                            icon: LucideIcons.users,
                            label: 'Manage Registrations',
                            iconBg: AppColors.infoLight,
                            iconFg: AppColors.info,
                            onTap: () => context.push('/registration-management'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OrgQuickTile(
                            icon: LucideIcons.megaphone,
                            label: 'Promote Event',
                            iconBg: AppColors.errorLight,
                            iconFg: AppColors.error,
                            onTap: () => context.push('/my-tournaments'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OrgQuickTile(
                            icon: LucideIcons.chartLine,
                            label: 'Analytics',
                            iconBg: AppColors.successLight,
                            iconFg: const Color(0xFF3FA55C),
                            onTap: () => context.push('/organizer-analytics'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),
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

/// Compact second/third event card under the featured one.
class _MiniEventCard extends StatelessWidget {
  final String title;
  final DateTime? date;
  final int registered;
  final VoidCallback onTap;

  const _MiniEventCard({
    required this.title,
    required this.date,
    required this.registered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
          boxShadow: SportXShadows.e1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${date == null ? 'TBA' : '${_monthLabel(date!)} ${date!.day}'} · $registered Registered',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _monShort = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];
String _monthLabel(DateTime d) => _monShort[d.month - 1];

class _EventCardSkeleton extends StatelessWidget {
  const _EventCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: SportXShadows.e1,
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: AppColors.borderSoft,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.borderSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 140,
                  decoration: BoxDecoration(
                    color: AppColors.borderSoft,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 18,
                  width: 110,
                  decoration: BoxDecoration(
                    color: AppColors.borderSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
