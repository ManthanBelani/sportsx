import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/organizer/presentation/widgets/organizer_kit.dart';
import 'package:sportx_app/features/trial/presentation/providers/unified_events_provider.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/core/role_config.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

/// Design board screen 7 · My Events — Upcoming / Ongoing / Completed pill
/// tabs, the "+ Create Event" button and the event cards (date block, banner,
/// registered count, "View" CTA and the ⋮ management menu).
class MyTournamentsManagementScreen extends ConsumerStatefulWidget {
  const MyTournamentsManagementScreen({super.key});

  @override
  ConsumerState<MyTournamentsManagementScreen> createState() =>
      _MyTournamentsManagementScreenState();
}

class _MyTournamentsManagementScreenState
    extends ConsumerState<MyTournamentsManagementScreen> {
  static const _tabs = ['Upcoming', 'Ongoing', 'Completed'];
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(myEventsProvider.notifier).load(filter: 'upcoming'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myEventsProvider);
    final canCreate = canCreateListings(ref.watch(authProvider).user?.role);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<UnifiedEvent> events;
    if (_tab == 0) {
      // Upcoming — published or draft, not started yet.
      events = state.events.where((e) {
        final s = e.startDate;
        if (s == null) return e.status != 'closed';
        final d = DateTime(s.year, s.month, s.day);
        return !d.isBefore(today) && e.status != 'closed';
      }).toList();
    } else if (_tab == 1) {
      // Ongoing — started and not finished yet.
      events = state.events.where((e) {
        final s = e.startDate;
        if (s == null) return false;
        final d = DateTime(s.year, s.month, s.day);
        final end = e.endDate;
        if (d.isAfter(today)) return false;
        if (end == null) return d.isAtSameMomentAs(today);
        final ed = DateTime(end.year, end.month, end.day);
        return !ed.isBefore(today);
      }).toList();
    } else {
      // Completed — the backend "past" filter.
      events = state.events.where((e) {
        final s = e.startDate;
        if (s == null) return false;
        return DateTime(s.year, s.month, s.day).isBefore(today);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Events',
          style: GoogleFonts.sora(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              LucideIcons.history,
              size: 19,
              color: AppColors.textPrimary,
            ),
            onPressed: () => context.push('/my-registrations'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(myEventsProvider.notifier)
            .load(filter: _tab == 2 ? 'past' : 'upcoming'),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++) ...[
                    _tabChip(_tabs[i], i == _tab, () {
                      setState(() => _tab = i);
                      ref
                          .read(myEventsProvider.notifier)
                          .load(filter: i == 2 ? 'past' : 'upcoming');
                    }),
                    if (i != _tabs.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            if (canCreate)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: PrimaryButton(
                    small: true,
                    label: '+ Create Event',
                    icon: LucideIcons.plus,
                    onPressed: () => context.push('/post-tournament'),
                  ),
                ),
              ),
            Expanded(
              child: state.isLoading && state.events.isEmpty
                  ? const GenericListSkeleton()
                  : events.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.calendarX,
                                size: 56,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _tab == 2
                                    ? 'No completed events yet'
                                    : 'No ${_tabs[_tab].toLowerCase()} events',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: events.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _eventCard(events[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventCard(UnifiedEvent e) {
    return OrgEventCard(
      title: e.name,
      start: e.startDate,
      end: e.endDate,
      location: e.locationLabel,
      sportName: e.sportName,
      bannerUrl: e.bannerUrl,
      registrationsOpen: e.registrationsOpen,
      registeredCount: e.registeredCount,
      onTap: () => _openEvent(e),
      onView: () => _openEvent(e),
      trailing: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: const Icon(
          LucideIcons.moreVertical,
          size: 16,
          color: AppColors.textSecondary,
        ),
        onSelected: (v) => _onMenu(v, e),
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'registrations',
            child: Text('Registrations'),
          ),
          if (e.isTournament)
            const PopupMenuItem(value: 'capacity', child: Text('Capacity')),
          if (e.isTournament)
            const PopupMenuItem(value: 'results', child: Text('Results')),
          if (e.status == 'draft')
            const PopupMenuItem(value: 'publish', child: Text('Publish')),
          if (e.status == 'published')
            const PopupMenuItem(value: 'close', child: Text('Close')),
        ],
      ),
    );
  }

  void _openEvent(UnifiedEvent e) {
    // Tournaments → Event Details & Management (design board screen 8);
    // trials → their registrant management (approve/reject) screen.
    context.push(
      e.isTournament ? '/organizer-event/${e.id}' : '/registrant-list',
      extra: {'id': e.id, 'title': e.name},
    );
  }

  Future<void> _onMenu(String v, UnifiedEvent e) async {
    switch (v) {
      case 'registrations':
        context.push(
          e.isTournament ? '/registration-management' : '/registrant-list',
          extra: {'id': e.id, 'title': e.name},
        );
        break;
      case 'capacity':
        context.push('/capacity-management', extra: {'id': e.id});
        break;
      case 'results':
        context.push(
          '/results-publishing',
          extra: {'id': e.id, 'title': e.name},
        );
        break;
      case 'publish':
        final ok = await ref
            .read(myEventsProvider.notifier)
            .publish(e.id, e.eventType);
        if (!mounted) return;
        if (ok) {
          SnackBarUtils.showSuccess(context, 'Event published');
        } else {
          SnackBarUtils.showError(context, 'Could not publish the event.');
        }
        break;
      case 'close':
        final ok = await ref
            .read(myEventsProvider.notifier)
            .close(e.id, e.eventType);
        if (!mounted) return;
        if (ok) {
          SnackBarUtils.showSuccess(context, 'Event closed');
        } else {
          SnackBarUtils.showError(context, 'Could not close the event.');
        }
        break;
    }
  }

  Widget _tabChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFFD54A),
                    Color(0xFFFFC107),
                    Color(0xFFF5B400),
                  ],
                )
              : null,
          color: active ? null : Colors.white,
          border: Border.all(
            color: active ? const Color(0x2E785000) : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
