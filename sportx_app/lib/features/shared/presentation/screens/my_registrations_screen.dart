import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/models/approval.dart';
import 'package:sportx_app/shared/providers/registration_provider.dart';
import 'package:sportx_app/features/trial/presentation/providers/unified_events_provider.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class MyRegistrationsScreen extends ConsumerWidget {
  const MyRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.88),
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          title: Text('My Registrations',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
          // v3 AT.9: Upcoming | Past
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'Upcoming'), Tab(text: 'Past')],
          ),
        ),
        body: const TabBarView(
          children: [
            _RegistrationsList(kind: 'upcoming'),
            _RegistrationsList(kind: 'past'),
          ],
        ),
      ),
    );
  }
}

ApprovalStatus _parseApprovalStatus(String? value) => ApprovalStatusX.fromString(value);

Color _approvalColor(ApprovalStatus status) => switch (status) {
      ApprovalStatus.approved => AppColors.success,
      ApprovalStatus.rejected => AppColors.error,
      ApprovalStatus.pending => AppColors.warning,
    };

IconData _approvalIcon(ApprovalStatus status) => switch (status) {
      ApprovalStatus.approved => LucideIcons.checkCircle,
      ApprovalStatus.rejected => LucideIcons.xCircle,
      ApprovalStatus.pending => LucideIcons.hourglass,
    };

class _RegistrationsList extends ConsumerWidget {
  /// v3 AT.9: one list that merges trial + tournament registrations and
  /// filters into Upcoming | Past based on the event's own date.
  final String kind; // 'upcoming' | 'past'
  const _RegistrationsList({required this.kind});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trials = ref.watch(myTrialRegistrationsProvider);
    final tournaments = ref.watch(myTournamentRegistrationsProvider);

    if (trials.isLoading || tournaments.isLoading) {
      return const GenericListSkeleton();
    }
    if (trials.hasError) {
      return Center(child: Text(ApiException.messageFor(trials.error!)));
    }
    if (tournaments.hasError) {
      return Center(child: Text(ApiException.messageFor(tournaments.error!)));
    }

    DateTime? parseDate(dynamic raw) {
      if (raw is String && raw.isNotEmpty) {
        return DateTime.tryParse(raw);
      }
      return null;
    }

    bool isUpcomingFor(Map<String, dynamic> reg, {required bool isTournament}) {
      if (isTournament) {
        final t = reg['tournament'];
        final start = parseDate(t is Map ? t['start_date'] : null);
        if (start == null) return reg['status'] != 'cancelled';
        return start.isAfter(DateTime.now().subtract(const Duration(days: 1)));
      }
      final t = reg['trial'];
      final start = parseDate(t is Map ? t['event_datetime'] : null);
      if (start == null) return reg['status'] != 'cancelled';
      return start.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    }

    final tList = (trials.value ?? []).cast<Map<String, dynamic>>();
    final tourList = (tournaments.value ?? []).cast<Map<String, dynamic>>();
    final entries = <Map<String, dynamic>>[
      ...tList.map((r) => {...r, '_kind': 'trial'}),
      ...tourList.map((r) => {...r, '_kind': 'tournament'}),
    ];
    final filtered = entries.where((r) => isUpcomingFor(r, isTournament: r['_kind'] == 'tournament') == (kind == 'upcoming')).toList()
      ..sort((a, b) {
        DateTime? da, db;
        final aT = a['_kind'] == 'tournament' ? a['tournament'] : a['trial'];
        final bT = b['_kind'] == 'tournament' ? b['tournament'] : b['trial'];
        da = parseDate(aT is Map ? (aT['start_date'] ?? aT['event_datetime']) : null);
        db = parseDate(bT is Map ? (bT['start_date'] ?? bT['event_datetime']) : null);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return kind == 'upcoming' ? da.compareTo(db) : db.compareTo(da);
      });

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          kind == 'upcoming' ? 'No upcoming registrations' : 'No past registrations',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myTrialRegistrationsProvider);
        ref.invalidate(myTournamentRegistrationsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, i) => _RegistrationCard(
          reg: filtered[i],
          isTournament: filtered[i]['_kind'] == 'tournament',
        ),
      ),
    );
  }
}

class _RegistrationCard extends ConsumerWidget {
  final Map<String, dynamic> reg;
  final bool isTournament;
  const _RegistrationCard({required this.reg, required this.isTournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalStatus = _parseApprovalStatus(reg['approval_status']?.toString());
    final color = _approvalColor(approvalStatus);
    final rejectionReason = reg['rejection_reason']?.toString();
    final name = isTournament
        ? (reg['tournament'] is Map
            ? (reg['tournament']['name'] ?? reg['tournament']['title'] ?? 'Tournament #${reg['tournament_id']}').toString()
            : 'Tournament #${reg['tournament_id']}')
        : (reg['trial'] is Map
            ? (reg['trial']['name'] ?? reg['trial']['title'] ?? 'Trial #${reg['trial_id']}').toString()
            : 'Trial #${reg['trial_id']}');
    final categoryName = reg['category'] is Map ? reg['category']['name']?.toString() : null;
    final registrationRef = reg['registration_ref']?.toString() ?? '';

    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (categoryName != null) Text('Category: $categoryName'),
            if (registrationRef.isNotEmpty) Text('Ref: $registrationRef'),
            const SizedBox(height: 4),
            Chip(
              label: Text(approvalStatus.label,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              backgroundColor: color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            if (approvalStatus == ApprovalStatus.rejected && (rejectionReason?.isNotEmpty == true))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Reason: $rejectionReason',
                    style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ),
            if (approvalStatus == ApprovalStatus.pending)
              TextButton(
                onPressed: () async {
                  final ok = await cancelRegistration(ref,
                      id: (reg['id'] ?? '').toString(), type: isTournament ? 'tournament' : 'trial');
                  if (context.mounted) {
                    if (ok) {
                      SnackBarUtils.showSuccess(context, 'Registration cancelled');
                      ref.invalidate(isTournament ? myTournamentRegistrationsProvider : myTrialRegistrationsProvider);
                    } else {
                      SnackBarUtils.showError(context, 'Could not cancel');
                    }
                  }
                },
                child: const Text('Cancel registration'),
              ),
          ],
        ),
        trailing: Icon(_approvalIcon(approvalStatus), color: color),
        isThreeLine: true,
      ),
    );
  }
}