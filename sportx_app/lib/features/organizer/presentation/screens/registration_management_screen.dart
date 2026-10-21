import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/date_format_utils.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class RegistrationManagementScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String title;
  const RegistrationManagementScreen({super.key, required this.tournamentId, required this.title});

  @override
  ConsumerState<RegistrationManagementScreen> createState() => _RegistrationManagementScreenState();
}

class _RegistrationManagementScreenState extends ConsumerState<RegistrationManagementScreen> {
  bool _exporting = false;

  /// Downloads the real CSV from the backend and hands it to the OS share
  /// sheet. The previous implementation only showed the character count of a
  /// locally built string — nothing was ever exported.
  Future<void> _exportCsv() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final resp = await ref.read(dioProvider).get(
        '/events/${widget.tournamentId}/registrations/export',
        queryParameters: {'type': 'tournament'},
        // The endpoint answers with text/csv — keep it as raw text.
        options: Options(responseType: ResponseType.plain),
      );
      final csv = resp.data is String
          ? resp.data as String
          : jsonEncode(resp.data);
      await Share.share(
        csv,
        subject: '${widget.title} — registrations',
      );
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e, 'Could not export the registrations.');
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final capacityAsync = ref.watch(tournamentCapacityProvider(widget.tournamentId));
    final tournamentAsync = ref.watch(tournamentDetailProvider(widget.tournamentId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Registrations', style: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: AppColors.border)),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: _exporting ? null : _exportCsv,
            icon: _exporting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.download, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: tournamentAsync.when(
        loading: () => const GenericDetailSkeleton(),
        error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(ApiException.messageFor(e), style: GoogleFonts.inter(color: AppColors.textSecondary)), const SizedBox(height: 12), SecondaryButton(label: 'Retry', onPressed: () => ref.invalidate(tournamentDetailProvider(widget.tournamentId)))])),
        data: (tournament) {
          final capacityList = capacityAsync.valueOrNull ?? [];
          final feeRaw = tournament.registrationFee ?? 0;
          final feePerTeam = (feeRaw > 0 ? feeRaw : 0).toInt();
          int spotsLeft = 0;
          int totalCapacity = 0;
          int totalRegistered = 0;
          if (capacityList.isNotEmpty) {
            for (final c in capacityList) {
              final max = (c['max_teams'] ?? c['capacity'] ?? 0) as int;
              final reg = (c['registered'] ?? 0) as int;
              totalCapacity += max;
              totalRegistered += reg;
            }
            spotsLeft = (totalCapacity - totalRegistered).clamp(0, 9999);
          }
          final venue = tournament.venue;
          final dateStr = tournament.startDate != null
              ? (tournament.endDate != null
                  ? '${DateFormatUtils.formatShortDate(tournament.startDate!.toIso8601String())} - ${DateFormatUtils.formatShortDate(tournament.endDate!.toIso8601String())}${venue != null ? ' • $venue' : ''}'
                  : '${DateFormatUtils.formatShortDate(tournament.startDate!.toIso8601String())}${venue != null ? ' • $venue' : ''}')
              : (venue ?? 'Tournament details pending');

          return _RegistrationsTabView(
            tournamentId: widget.tournamentId,
            title: widget.title,
            dateStr: dateStr,
            spotsLeft: spotsLeft,
            totalRegistered: totalRegistered,
            feePerTeam: feePerTeam,
            capacityList: capacityList,
            hasExternalRegistration: tournament.hasExternalRegistration,
            externalClicks: tournament.externalRegistrationClicks,
          );
        },
      ),
    );
  }
}

class _RegistrationsTabView extends ConsumerStatefulWidget {
  final String tournamentId;
  final String title;
  final String dateStr;
  final int spotsLeft;
  final int totalRegistered;
  final int feePerTeam;
  final List<Map<String, dynamic>> capacityList;
  final bool hasExternalRegistration;
  final int externalClicks;

  const _RegistrationsTabView({
    required this.tournamentId,
    required this.title,
    required this.dateStr,
    required this.spotsLeft,
    required this.totalRegistered,
    required this.feePerTeam,
    required this.capacityList,
    this.hasExternalRegistration = false,
    this.externalClicks = 0,
  });

  @override
  ConsumerState<_RegistrationsTabView> createState() => _RegistrationsTabViewState();
}

class _RegistrationsTabViewState extends ConsumerState<_RegistrationsTabView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title, style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(widget.dateStr, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _summaryItem('${widget.totalRegistered}', 'Registered')),
              const SizedBox(width: 10),
              Expanded(child: _summaryItem('${widget.spotsLeft}', 'Spots Left')),
            ]),
            // External registration tournaments have no in-app sign-ups — the
            // only signal we have is the number of clicks on the link.
            if (widget.hasExternalRegistration) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  const Icon(LucideIcons.externalLink, size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This tournament registers athletes on your own page. '
                      'SportX can only count link clicks, not the sign-ups made there.',
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.info),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${widget.externalClicks} clicks',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.info)),
                ]),
              ),
            ],
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search team / athlete',
              prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppColors.textSecondary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              suffixIcon: _query.isEmpty ? null : IconButton(icon: const Icon(LucideIcons.x, size: 14), onPressed: () { _searchCtrl.clear(); }),
            ),
          ),
        ),
        Container(
          color: AppColors.background,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.ink,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.ctaDark,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _RegistrationListView(tournamentId: widget.tournamentId, status: 'pending', feePerTeam: widget.feePerTeam, query: _query, hasExternalRegistration: widget.hasExternalRegistration),
              _RegistrationListView(tournamentId: widget.tournamentId, status: 'approved', feePerTeam: widget.feePerTeam, query: _query, hasExternalRegistration: widget.hasExternalRegistration),
              _RegistrationListView(tournamentId: widget.tournamentId, status: 'rejected', feePerTeam: widget.feePerTeam, query: _query, hasExternalRegistration: widget.hasExternalRegistration),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(String num, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Text(num, style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _RegistrationListView extends ConsumerWidget {
  final String tournamentId;
  final String status;
  final int feePerTeam;
  final String query;
  final bool hasExternalRegistration;

  const _RegistrationListView({
    required this.tournamentId,
    required this.status,
    required this.feePerTeam,
    this.query = '',
    this.hasExternalRegistration = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tournamentRegistrationsByStatusProvider((tournamentId: tournamentId, status: status)));

    return async.when(
      loading: () => const GenericListSkeleton(itemCount: 5),
      error: (e, _) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(ApiException.messageFor(e), style: GoogleFonts.inter(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          SecondaryButton(label: 'Retry', onPressed: () => ref.invalidate(tournamentRegistrationsByStatusProvider((tournamentId: tournamentId, status: status)))),
        ]),
      ),
      data: (regs) {
        // client-side search filter + bulk CSV helper
        List<Map<String, dynamic>> filtered = regs;
        if (query.isNotEmpty) {
          filtered = regs.where((r) {
            final athlete = r['athlete'] is Map ? r['athlete'] as Map : null;
            final user = athlete != null && athlete['user'] is Map ? athlete['user'] as Map : null;
            final hay = '${r['team_name'] ?? ''} ${user?['name'] ?? ''} ${r['category']?['name'] ?? ''}'.toLowerCase();
            return hay.contains(query);
          }).toList();
        }
        if (filtered.isEmpty && query.isNotEmpty) {
          return Center(child: Text('No results for "$query"', style: GoogleFonts.inter(color: AppColors.textSecondary)));
        }
        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                hasExternalRegistration
                    ? 'No $status registrations — athletes register on your own page.'
                    : 'No $status registrations',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final r in filtered) {
          final catName = (r['category'] is Map ? r['category']['name'] : r['category_name'])?.toString() ?? 'Uncategorized';
          grouped.putIfAbsent(catName, () => []).add(r);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(tournamentRegistrationsByStatusProvider((tournamentId: tournamentId, status: status))),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text('${filtered.length} $status', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ),
              ...grouped.entries.map((entry) => Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(entry.key, style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        Text('${entry.value.length} registrations', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primaryDarker, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 10),
                      ...entry.value.map((r) => _RegistrationCard(tournamentId: tournamentId, data: r, status: status, feePerTeam: feePerTeam)),
                      const SizedBox(height: 16),
                    ]),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _RegistrationCard extends ConsumerWidget {
  final String tournamentId;
  final Map<String, dynamic> data;
  final String status;
  final int feePerTeam;

  const _RegistrationCard({required this.tournamentId, required this.data, required this.status, required this.feePerTeam});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athlete = data['athlete'] is Map ? data['athlete'] as Map : null;
    final user = athlete != null && athlete['user'] is Map ? athlete['user'] as Map : null;
    final name = (data['team_name'] ?? user?['name'] ?? 'Participant').toString();
    final approvalStatus = (data['approval_status'] ?? data['status'] ?? 'pending').toString();
    final rejectionReason = data['rejection_reason']?.toString();
    final avatarUrl = user?['avatar_url'] ?? athlete?['photo_url'];
    final resolvedAvatar = MediaUtils.resolveNullable(avatarUrl?.toString());
    final isPending = approvalStatus == 'pending';
    final isPaid = (data['payment_status'] ?? data['status'] ?? '') == 'paid';
    final feeLabel = feePerTeam > 0 ? '₹$feePerTeam' : 'TBD';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: SportXShadows.e1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 18, backgroundColor: AppColors.yellowSoft, backgroundImage: resolvedAvatar != null ? NetworkImage(resolvedAvatar) : null, child: resolvedAvatar == null ? const Icon(LucideIcons.user, size: 16, color: AppColors.textSecondary) : null),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
              Text('${data['participation_type'] ?? ''} • $approvalStatus', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ])),
            StatusPill(
              label: approvalStatus,
              kind: approvalStatus == 'approved'
                  ? PillKind.ok
                  : approvalStatus == 'rejected'
                      ? PillKind.no
                      : PillKind.pending,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPaid ? AppColors.successLight : AppColors.yellowTint,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: isPaid ? AppColors.success.withValues(alpha: 0.35) : AppColors.yellowDeep.withValues(alpha: 0.35)),
              ),
              child: Text(isPaid ? 'Paid $feeLabel' : 'Fee Pending', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: isPaid ? AppColors.success : AppColors.warnText)),
            ),
          ]),
          if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Reason: $rejectionReason', style: GoogleFonts.inter(fontSize: 12, color: AppColors.error)),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              GestureDetector(
                onTap: () => _showRejectDialog(context, ref, data),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                  alignment: Alignment.center,
                  child: Text('Reject', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error)),
                ),
              ),
              const SizedBox(width: 8),
              PrimaryButton(small: true, label: 'Approve', icon: LucideIcons.check, onPressed: () => _approve(context, ref, data)),
            ]),
          ],
        ]),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref, Map<String, dynamic> r) async {
    final id = r['id'].toString();
    final (ok, error) = await ref.read(providerTournamentActionsProvider).approveRegistration(id);
    if (context.mounted) {
      if (ok) {
        SnackBarUtils.showSuccess(context, 'Registration approved');
      } else {
        SnackBarUtils.showError(context, error ?? 'Failed to approve. Please try again.');
      }
      if (ok) {
        ref.invalidate(tournamentRegistrationsByStatusProvider((tournamentId: tournamentId, status: 'pending')));
        ref.invalidate(tournamentRegistrationsByStatusProvider((tournamentId: tournamentId, status: 'approved')));
        ref.invalidate(organizerAnalyticsProvider);
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> r) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Registration'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason for rejection', hintText: 'Enter reason...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
          PrimaryButton(small: true, label: 'Reject', onPressed: () => Navigator.pop(context, controller.text)),
        ],
      ),
    );
    if (reason != null && reason.trim().isNotEmpty && context.mounted) {
      final (ok, error) = await ref.read(providerTournamentActionsProvider).rejectRegistration(r['id'].toString(), reason.trim());
      if (context.mounted) {
        if (ok) {
          SnackBarUtils.showSuccess(context, 'Registration rejected');
        } else {
          SnackBarUtils.showError(context, error ?? 'Failed to reject. Please try again.');
        }
        if (ok) {
          ref.invalidate(tournamentRegistrationsByStatusProvider((tournamentId: tournamentId, status: 'pending')));
          ref.invalidate(tournamentRegistrationsByStatusProvider((tournamentId: tournamentId, status: 'rejected')));
          ref.invalidate(organizerAnalyticsProvider);
        }
      }
    }
  }
}

