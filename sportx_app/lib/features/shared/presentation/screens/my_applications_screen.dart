import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/registration_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// v2 my-applications.html — athlete Activity: Applications / Registrations /
/// Enquiries tabs. Applications aggregates the existing trial + tournament
/// registration providers; tapping a row opens /application-status.
class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.88),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.ink),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          title: Text('Activity',
              style: GoogleFonts.sora(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          bottom: TabBar(
            labelColor: AppColors.primaryDarker,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.yellow,
            indicatorWeight: 2.5,
            labelStyle: GoogleFonts.inter(
                fontSize: 13.5, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 13.5, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Applications'),
              Tab(text: 'Registrations'),
              Tab(text: 'Enquiries'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ApplicationsTab(ref: ref),
            _RegistrationsTab(),
            _EnquiriesTab(),
          ],
        ),
      ),
    );
  }
}

PillKind _pillFor(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
    case 'shortlisted':
    case 'accepted':
      return PillKind.ok;
    case 'rejected':
    case 'closed':
      return PillKind.no;
    default:
      return PillKind.pending;
  }
}

String _pillLabel(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 'Under Review';
    case 'approved':
      return 'Shortlisted';
    case 'rejected':
      return 'Closed';
    default:
      return status.isEmpty
          ? 'Under Review'
          : status[0].toUpperCase() + status.substring(1);
  }
}

class _ApplicationsTab extends StatelessWidget {
  final WidgetRef ref;
  const _ApplicationsTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final trialRegs = ref.watch(myTrialRegistrationsProvider);
    final tourRegs = ref.watch(myTournamentRegistrationsProvider);

    return trialRegs.when(
      data: (trials) => tourRegs.when(
        data: (tours) {
          final rows = <Widget>[];
          for (final reg in trials) {
            final trial = reg['trial'] is Map
                ? Map<String, dynamic>.from(reg['trial'] as Map)
                : null;
            final name = trial?['name']?.toString() ??
                trial?['title']?.toString() ??
                'Trial #${reg['trial_id']}';
            final status =
                (reg['approval_status'] ?? 'pending').toString();
            final refCode =
                (reg['registration_ref'] ?? '').toString();
            rows.add(_appRow(
              context,
              initial: name.isNotEmpty ? name[0].toUpperCase() : 'T',
              title: name,
              subtitle:
                  'Applied${refCode.isNotEmpty ? ' · $refCode' : ''}',
              status: status,
              onTap: () => context.push('/application-status', extra: {
                'kind': 'trial',
                'title': name,
                'ref': refCode,
                'status': status,
              }),
            ));
          }
          for (final reg in tours) {
            final tournament = reg['tournament'] is Map
                ? Map<String, dynamic>.from(reg['tournament'] as Map)
                : null;
            final name = tournament?['name']?.toString() ??
                tournament?['title']?.toString() ??
                'Tournament #${reg['tournament_id']}';
            final status =
                (reg['approval_status'] ?? 'pending').toString();
            rows.add(_appRow(
              context,
              initial: name.isNotEmpty ? name[0].toUpperCase() : 'C',
              title: name,
              subtitle: 'Registered',
              status: status,
              onTap: () => context.push('/application-status', extra: {
                'kind': 'tournament',
                'title': name,
                'ref': '',
                'status': status,
              }),
            ));
          }
          if (rows.isEmpty) {
            return Center(
                child: Text('No applications yet',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textSecondary)));
          }
          return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: rows);
        },
        loading: () => const GenericListSkeleton(),
        error: (_, _) => _errorReload(
            context, () => ref.invalidate(myTournamentRegistrationsProvider)),
      ),
      loading: () => const GenericListSkeleton(),
      error: (_, _) => _errorReload(
          context, () => ref.invalidate(myTrialRegistrationsProvider)),
    );
  }

  Widget _appRow(BuildContext context,
      {required String initial,
      required String title,
      required String subtitle,
      required String status,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFE9A8),
                      Color(0xFFFFC107),
                      Color(0xFFF5B400)
                    ]),
              ),
              alignment: Alignment.center,
              child: Text(initial,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(subtitle,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ),
                      StatusPill(
                          label: _pillLabel(status),
                          kind: _pillFor(status)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorReload(BuildContext context, VoidCallback retry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Could not load applications',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Retry', small: true, onPressed: retry),
        ],
      ),
    );
  }
}

class _RegistrationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        EntityRow(
            title: 'My Registrations',
            subtitle: 'Trials & tournaments',
            avatarText: 'R',
            onTap: () => context.push('/my-registrations')),
        EntityRow(
            title: 'My Trials',
            subtitle: 'Track trial registrations',
            avatarText: 'T',
            onTap: () => context.push('/my-trials')),
        EntityRow(
            title: 'My Tournaments',
            subtitle: 'Track tournament entries',
            avatarText: 'C',
            onTap: () => context.push('/my-tournaments')),
        EntityRow(
            title: 'My Sponsorships',
            subtitle: 'Sponsorship applications',
            avatarText: 'S',
            onTap: () => context.push('/my-sponsorships')),
        EntityRow(
            title: 'Browse Opportunities',
            subtitle: 'Trials, tournaments & more',
            avatarText: 'O',
            onTap: () => context.push('/opportunities')),
      ],
    );
  }
}

class _EnquiriesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        EntityRow(
            title: 'My Enquiries',
            subtitle: 'Coach & academy enquiries',
            avatarText: 'E',
            onTap: () => context.push('/enquiry-inbox')),
        EntityRow(
            title: 'Coaching Enrollments',
            subtitle: 'My coaching programs',
            avatarText: 'C',
            onTap: () => context.push('/my-coaching-enrollments')),
      ],
    );
  }
}
