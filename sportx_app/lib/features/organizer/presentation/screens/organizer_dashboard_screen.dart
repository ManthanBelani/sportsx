import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';

class OrganizerDashboardScreen extends ConsumerStatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  ConsumerState<OrganizerDashboardScreen> createState() => _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends ConsumerState<OrganizerDashboardScreen> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(myTrialsProvider.notifier).refresh();
      ref.read(myTournamentsProvider.notifier).refresh();
      // warm analytics
      ref.read(organizerAnalyticsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('SportX', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, color: AppColors.textPrimary),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: switch (_currentTabIndex) {
        0 => _buildHomeTab(),
        1 => _buildEventsTab(),
        2 => _buildAnalyticsTab(),
        3 => _buildProfileTab(),
        _ => _buildHomeTab(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) => setState(() => _currentTabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.home),
            selectedIcon: Icon(LucideIcons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.calendar),
            selectedIcon: Icon(LucideIcons.calendar, color: AppColors.primary),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.barChart2),
            selectedIcon: Icon(LucideIcons.barChart2, color: AppColors.primary),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.user),
            selectedIcon: Icon(LucideIcons.user, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final trialsState = ref.watch(myTrialsProvider);
    final tournamentsState = ref.watch(myTournamentsProvider);
    final trials = trialsState.items;
    final tournaments = tournamentsState.items;
    final analyticsAsync = ref.watch(organizerAnalyticsProvider);

    if ((trialsState.isLoading && trials.isEmpty) ||
        (tournamentsState.isLoading && tournaments.isEmpty)) {
      return const SponsorDashboardSkeleton();
    }

    final analytics = analyticsAsync.valueOrNull;
    final pendingCount = analytics?.pendingRegistrations ?? 0;
    final approvedCount = analytics?.approvedRegistrations ?? 0;
    final totalRegs = analytics?.totalRegistrations ??
        (trials.fold<int>(0, (s, t) => s + (t.filledSpots ?? 0)) +
            tournaments.fold<int>(0, (s, t) => s + (t.filledSpots ?? 0)));

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(myTrialsProvider.notifier).refresh();
        await ref.read(myTournamentsProvider.notifier).refresh();
        ref.invalidate(organizerAnalyticsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics stats row (live from backend if available)
            Row(
              children: [
                Expanded(child: _buildStatCard('${analytics?.publishedTrials ?? trials.where((t) => t.status == 'published').length}', 'Active Trials')),
                const SizedBox(width: 10),
                Expanded(child: _buildStatCard('${analytics?.publishedTournaments ?? tournaments.where((t) => t.status == 'published').length}', 'Tournaments')),
                const SizedBox(width: 10),
                Expanded(child: _buildStatCard('$totalRegs', 'Registrations')),
              ],
            ),
            const SizedBox(height: 10),
            if (analytics != null)
              Row(
                children: [
                  Expanded(child: _buildStatCard('$pendingCount', 'Pending', color: Colors.orange)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard('$approvedCount', 'Approved', color: AppColors.success)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard('${analytics.approvalRate}%', 'Approval Rate')),
                ],
              ),
            if (analytics != null) const SizedBox(height: 12),

            // Capacity utilization bar if available
            if (analytics != null && analytics.totalCapacity > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Capacity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('${analytics.utilizationPercent}% filled', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (analytics.totalRegistered / analytics.totalCapacity).clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${analytics.totalRegistered}/${analytics.totalCapacity} spots • ${analytics.spotsLeft} left • ₹${analytics.revenueEstimate.toStringAsFixed(0)} est. revenue',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ]),
              ),
            if (analytics != null && analytics.totalCapacity > 0) const SizedBox(height: 12),

            // Pending approvals banner
            if (pendingCount > 0)
              InkWell(
                onTap: () {
                  if (tournaments.isNotEmpty) {
                    context.push('/registration-management', extra: {'id': tournaments.first.id.toString(), 'title': tournaments.first.title});
                  } else {
                    context.push('/my-tournaments');
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFfef3c7), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFfde68a))),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                      child: const Icon(LucideIcons.clock, size: 18, color: Color(0xFFd97706)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('$pendingCount pending approval${pendingCount == 1 ? '' : 's'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF92400e))),
                        const Text('Tap to review and approve/reject', style: TextStyle(fontSize: 11, color: Color(0xFF92400e))),
                      ]),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF92400e)),
                  ]),
                ),
              ),
            if (pendingCount > 0) const SizedBox(height: 12),

            // Deadline Alert
            if (analytics?.deadlineAlert != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(LucideIcons.clock, size: 20, color: Color(0xFFdc2626)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13, color: Color(0xFFdc2626), fontFamily: 'Inter'),
                        children: [
                          const TextSpan(text: 'Deadline approaching: ', style: TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(text: '${analytics!.deadlineAlert!['tournament_name']} closes in '),
                          TextSpan(text: '${analytics.deadlineAlert!['days_left']} days', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ]),
              )
            else if (_hasDeadlineAlert(tournaments))
              _legacyDeadlineAlert(tournaments),
            const SizedBox(height: 16),

            // Quick Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _buildQuickAction(LucideIcons.clipboardList, 'Post Trial', () => context.push('/post-trial')),
                  _buildQuickAction(LucideIcons.trophy, 'Post Tournament', () => context.push('/post-tournament')),
                  _buildQuickAction(LucideIcons.users, 'Registrations', () => context.push('/my-tournaments')),
                  _buildQuickAction(LucideIcons.barChart3, 'Analytics', () => context.push('/organizer-analytics')),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _buildQuickAction(LucideIcons.messageCircle, 'Enquiries', () => context.push('/enquiry-inbox')),
                  _buildQuickAction(LucideIcons.layers, 'Capacity', () {
                    if (tournaments.isNotEmpty) context.push('/capacity-management', extra: {'id': tournaments.first.id.toString()});
                  }),
                  _buildQuickAction(LucideIcons.award, 'Results', () {
                    if (tournaments.isNotEmpty) context.push('/results-publishing', extra: {'id': tournaments.first.id.toString(), 'title': tournaments.first.title});
                  }),
                  _buildQuickAction(LucideIcons.calendar, 'Schedule', () => context.push('/tournament-calendar')),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // Pending registrations preview (category breakdown first entry)
            if (analytics != null && analytics.categoryBreakdown.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Capacity by Category', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () => context.push('/organizer-analytics'),
                      child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  ...analytics.categoryBreakdown.take(2).map((cat) {
                    final cap = (cat['capacity'] ?? 0) as int;
                    final reg = (cat['registered'] ?? 0) as int;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: Text('${cat['tournament_name']} • ${cat['category_name']}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
                          Text('$reg/$cap', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: cap == 0 ? 0 : (reg / cap).clamp(0, 1),
                            minHeight: 5,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ]),
                    );
                  }),
                ]),
              ),
            if (analytics != null && analytics.categoryBreakdown.isNotEmpty) const SizedBox(height: 16),

            // My Trials
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('My Trials', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  GestureDetector(onTap: () => context.push('/my-trials'), child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.primary))),
                ]),
                const SizedBox(height: 12),
                if (trials.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No trials yet. Tap Post Trial to create one.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)))
                else
                  ...trials.take(3).map((t) => InkWell(
                        onTap: () => context.push('/registrant-list', extra: {'id': t.id.toString(), 'title': t.title}),
                        borderRadius: BorderRadius.circular(8),
                        child: _buildEventItem(
                          t.title,
                          t.trialDate != null ? '${t.trialDate!.day}/${t.trialDate!.month}/${t.trialDate!.year} • ${t.filledSpots ?? 0} registrations' : '${t.filledSpots ?? 0} registrations',
                          t.status[0].toUpperCase() + t.status.substring(1),
                          LucideIcons.circleDot,
                        ),
                      )),
              ]),
            ),
            const SizedBox(height: 16),

            // My Tournaments with management shortcuts
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('My Tournaments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  GestureDetector(onTap: () => context.push('/my-tournaments'), child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.primary))),
                ]),
                const SizedBox(height: 12),
                if (tournaments.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No tournaments yet. Tap Post Tournament to create one.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)))
                else
                  ...tournaments.take(3).map((t) => InkWell(
                        onTap: () => context.push('/registration-management', extra: {'id': t.id.toString(), 'title': t.title}),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(children: [
                          _buildEventItem(
                            t.title,
                            t.startDate != null && t.endDate != null
                                ? '${t.startDate!.day}/${t.startDate!.month}–${t.endDate!.day}/${t.endDate!.month}/${t.endDate!.year} • ${t.filledSpots ?? 0} registered'
                                : '${t.filledSpots ?? 0} registered',
                            t.status[0].toUpperCase() + t.status.substring(1),
                            LucideIcons.trophy,
                          ),
                          if (t.status == 'published')
                            Padding(
                              padding: const EdgeInsets.only(left: 56, bottom: 8),
                              child: Row(children: [
                                _smallAction('Registrations', LucideIcons.users, () => context.push('/registration-management', extra: {'id': t.id.toString(), 'title': t.title})),
                                const SizedBox(width: 8),
                                _smallAction('Capacity', LucideIcons.layers, () => context.push('/capacity-management', extra: {'id': t.id.toString()})),
                                const SizedBox(width: 8),
                                _smallAction('Results', LucideIcons.award, () => context.push('/results-publishing', extra: {'id': t.id.toString(), 'title': t.title})),
                              ]),
                            ),
                        ]),
                      )),
              ]),
            ),
            const SizedBox(height: 16),
            // Logout handled in Profile tab, keep hidden here
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    final tournamentsState = ref.watch(myTournamentsProvider);
    final trialsState = ref.watch(myTrialsProvider);
    final tournaments = tournamentsState.items;
    final trials = trialsState.items;
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(myTournamentsProvider.notifier).refresh();
        await ref.read(myTrialsProvider.notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('My Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            FilledButton.icon(onPressed: () => context.push('/post-tournament'), icon: const Icon(LucideIcons.plus, size: 16), label: const Text('New Event')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Tournaments (${tournaments.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                TextButton(onPressed: () => context.push('/my-tournaments'), child: const Text('Manage All')),
              ]),
              if (tournaments.isEmpty)
                const Text('No tournaments yet.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
              else
                ...tournaments.take(5).map((t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(t.status, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          final id = t.id.toString();
                          switch (v) {
                            case 'registrations':
                              context.push('/registration-management', extra: {'id': id, 'title': t.title});
                              break;
                            case 'capacity':
                              context.push('/capacity-management', extra: {'id': id});
                              break;
                            case 'results':
                              context.push('/results-publishing', extra: {'id': id, 'title': t.title});
                              break;
                            case 'view':
                              context.push('/tournament-detail/${t.id}');
                              break;
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'registrations', child: Text('Manage Registrations')),
                          PopupMenuItem(value: 'capacity', child: Text('Manage Capacity')),
                          PopupMenuItem(value: 'results', child: Text('Publish Results')),
                          PopupMenuItem(value: 'view', child: Text('View Detail')),
                        ],
                      ),
                      onTap: () => context.push('/registration-management', extra: {'id': t.id.toString(), 'title': t.title}),
                    )),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Trials (${trials.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                TextButton(onPressed: () => context.push('/my-trials'), child: const Text('Manage All')),
              ]),
              if (trials.isEmpty)
                const Text('No trials yet.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
              else
                ...trials.take(5).map((t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(t.status, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
                      onTap: () => context.push('/registrant-list', extra: {'id': t.id.toString(), 'title': t.title}),
                    )),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final async = ref.watch(organizerAnalyticsProvider);
    return async.when(
      loading: () => const GenericListSkeleton(itemCount: 6),
      error: (e, _) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Failed to load analytics', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(e.toString(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => ref.invalidate(organizerAnalyticsProvider), child: const Text('Retry')),
          const SizedBox(height: 8),
          TextButton(onPressed: () => context.push('/organizer-analytics'), child: const Text('Open full analytics')),
        ]),
      ),
      data: (a) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Row(children: [
            Expanded(child: _buildStatCard('${a.totalRegistrations}', 'Total')),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('${a.pendingRegistrations}', 'Pending', color: Colors.orange)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('${a.approvedRegistrations}', 'Approved', color: AppColors.success)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('${a.approvalRate}%', 'Rate')),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Revenue & Capacity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Estimated revenue: ₹${a.revenueEstimate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('${a.totalRegistered}/${a.totalCapacity} capacity • ${a.utilizationPercent}% utilized', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => context.push('/organizer-analytics'), child: const Text('View detailed analytics')),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildProfileTab() {
    final user = ref.watch(authProvider).user;
    final orgAsync = ref.watch(myOrganizerProvider);
    final org = orgAsync.valueOrNull;
    final orgName = (org?['organization_name'] ?? user?.name ?? 'Organizer').toString();
    final orgType = (org?['org_type'] ?? 'organizer').toString();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: const Icon(LucideIcons.building2, color: Colors.white, size: 32)),
            const SizedBox(height: 12),
            Text(orgName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(user?.email ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(orgType, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: user?.isVerified == true ? const Color(0xFFd1fae5) : const Color(0xFFfef3c7), borderRadius: BorderRadius.circular(12)), child: Text(user?.isVerified == true ? 'Verified • Organizer' : 'Pending verification • Organizer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: user?.isVerified == true ? const Color(0xFF065f46) : const Color(0xFF92400e)))),
            if (orgAsync.isLoading) const Padding(padding: EdgeInsets.only(top: 8), child: SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))),
            if (orgAsync.hasError) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Failed to load org profile', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          ]),
        ),
        const SizedBox(height: 16),
        _profileAction('Edit Organization', LucideIcons.edit3, () => context.push('/organizer-profile')),
        _profileAction('My Tournaments', LucideIcons.trophy, () => context.push('/my-tournaments')),
        _profileAction('My Trials', LucideIcons.clipboardList, () => context.push('/my-trials')),
        _profileAction('Enquiry Inbox', LucideIcons.messageCircle, () => context.push('/enquiry-inbox')),
        _profileAction('Notifications', LucideIcons.bell, () => context.push('/notifications')),
        _profileAction('Settings', LucideIcons.settings, () => context.push('/settings')),
        _profileAction('Help & Support', LucideIcons.helpCircle, () => context.push('/help-support')),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async => await ref.read(authProvider.notifier).logout(),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          icon: const Icon(LucideIcons.logOut, size: 18),
          label: const Text('Log out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _profileAction(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
      child: ListTile(leading: Icon(icon, size: 18, color: AppColors.textPrimary), title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)), trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary), onTap: onTap),
    );
  }

  bool _hasDeadlineAlert(List tournaments) {
    for (final t in tournaments) {
      if (t.registrationDeadline != null && t.status == 'published') {
        final daysLeft = t.registrationDeadline!.difference(DateTime.now()).inDays;
        if (daysLeft >= 0 && daysLeft <= 7) return true;
      }
    }
    return false;
  }

  Widget _legacyDeadlineAlert(List tournaments) {
    dynamic deadlineTournament;
    DateTime? nearestDeadline;
    for (final t in tournaments) {
      if (t.registrationDeadline != null && t.status == 'published') {
        final daysLeft = t.registrationDeadline!.difference(DateTime.now()).inDays;
        if (daysLeft >= 0 && daysLeft <= 7) {
          if (nearestDeadline == null || t.registrationDeadline!.isBefore(nearestDeadline)) {
            nearestDeadline = t.registrationDeadline;
            deadlineTournament = t;
          }
        }
      }
    }
    if (deadlineTournament == null || nearestDeadline == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(LucideIcons.clock, size: 20, color: Color(0xFFdc2626)),
        const SizedBox(width: 10),
        Expanded(child: RichText(text: TextSpan(style: const TextStyle(fontSize: 13, color: Color(0xFFdc2626), fontFamily: 'Inter'), children: [const TextSpan(text: 'Deadline approaching: ', style: TextStyle(fontWeight: FontWeight.w600)), TextSpan(text: '${deadlineTournament.title} registration closes in '), TextSpan(text: '${nearestDeadline.difference(DateTime.now()).inDays} days', style: const TextStyle(fontWeight: FontWeight.w600))]))),
      ]),
    );
  }

  Widget _buildStatCard(String value, String label, {Color color = AppColors.primary}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), alignment: Alignment.center, child: Icon(icon, size: 20, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _smallAction(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 11, color: AppColors.textSecondary), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))]),
      ),
    );
  }

  Widget _buildEventItem(String title, String meta, String status, IconData icon) {
    Color badgeColor;
    Color badgeText;
    if (status == 'Active' || status == 'Published') {
      badgeColor = const Color(0xFFd1fae5);
      badgeText = const Color(0xFF065f46);
    } else if (status == 'Draft') {
      badgeColor = const Color(0xFFfef3c7);
      badgeText = const Color(0xFF92400e);
    } else {
      badgeColor = AppColors.surface;
      badgeText = AppColors.textSecondary;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), alignment: Alignment.center, child: Icon(icon, size: 20, color: AppColors.textPrimary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)), const SizedBox(height: 2), Text(meta, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)), child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeText))),
      ]),
    );
  }
}
