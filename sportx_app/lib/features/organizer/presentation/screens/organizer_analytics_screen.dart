import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/features/organizer/presentation/widgets/organizer_kit.dart';
import 'package:sportx_app/features/trial/presentation/providers/unified_events_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/home_kit.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Design board screen 10 · My Analytics — event selector row, the
/// Registrations line chart with the 7D / 30D / 3M / 1Y range pills, the 2×2
/// KPI grid (Total / Approved / Pending / Revenue) and the "Top Sources" bar
/// list.
class OrganizerAnalyticsScreen extends ConsumerStatefulWidget {
  const OrganizerAnalyticsScreen({super.key});

  @override
  ConsumerState<OrganizerAnalyticsScreen> createState() =>
      _OrganizerAnalyticsScreenState();
}

class _OrganizerAnalyticsScreenState
    extends ConsumerState<OrganizerAnalyticsScreen> {
  /// Range pill index → days of history for the chart.
  static const _ranges = <({String label, int days})>[
    (label: '7D', days: 7),
    (label: '30D', days: 30),
    (label: '3M', days: 90),
    (label: '1Y', days: 365),
  ];
  int _range = 1;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(organizerAnalyticsProvider);
    final myEvents = ref.watch(myEventsProvider);

    // Event selector — "All Events" plus each of the organizer's events.
    final events = myEvents.events;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Event Analytics',
          style: GoogleFonts.sora(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              LucideIcons.refreshCw,
              size: 18,
              color: AppColors.textPrimary,
            ),
            onPressed: () => ref.invalidate(organizerAnalyticsProvider),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: async.when(
        loading: () => const GenericListSkeleton(itemCount: 6),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ApiException.messageFor(e),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Retry',
                onPressed: () => ref.invalidate(organizerAnalyticsProvider),
              ),
            ],
          ),
        ),
        data: (a) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(organizerAnalyticsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              // ── Event selector ────────────────────────────────────────
              Text(
                'Event',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: SportXShadows.e1,
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.trophy,
                      size: 15,
                      color: AppColors.primaryDarker,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All Events',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      '${events.length} live',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Registrations chart card ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: SportXShadows.e1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Registrations',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < _ranges.length; i++) ...[
                              _rangePill(
                                _ranges[i].label,
                                i == _range,
                                () => setState(() => _range = i),
                              ),
                              if (i != _ranges.length - 1)
                                const SizedBox(width: 5),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${a.totalRegistrations} total',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: Builder(
                        builder: (context) {
                          final series = a.seriesFor(_ranges[_range].days);
                          if (series.isEmpty) {
                            return Center(
                              child: Text(
                                'No registrations in this window yet',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            );
                          }
                          // Label every few points so the axis stays readable.
                          final step = (series.length / 4).ceil().clamp(
                            1,
                            series.length,
                          );
                          final labels = <String>[];
                          for (var i = 0; i < series.length; i++) {
                            labels.add(
                              i % step == 0 ? _shortDate(series[i].date) : '',
                            );
                          }
                          return OrgLineChart(
                            values: [
                              for (final p in series) p.count.toDouble(),
                            ],
                            xLabels: labels,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── 2×2 KPI grid ──────────────────────────────────────────
              // ── KpiTile ×4 — design board: Views / Registrations /
              // Revenue / Inquiries ──────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OrgKpiTile(
                      value: compactIndianNumber(a.views),
                      label: 'Views',
                      icon: LucideIcons.eye,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OrgKpiTile(
                      value: '${a.totalRegistrations}',
                      label: 'Registrations',
                      icon: LucideIcons.users,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OrgKpiTile(
                      value: '₹${compactIndianNumber(a.revenueEstimate)}',
                      label: 'Revenue',
                      icon: LucideIcons.indianRupee,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OrgKpiTile(
                      value: '${a.inquiries}',
                      label: 'Inquiries',
                      icon: LucideIcons.mail,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Top sources ───────────────────────────────────────────
              Text(
                'Top Sources',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              if (a.topSources.isEmpty)
                emptyHint(
                  'Registrations will show where your audience comes from.',
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: SportXShadows.e1,
                  ),
                  child: Column(
                    children: [
                      for (final s in a.topSources) ...[
                        OrgBarRow(
                          label: (s['name'] ?? 'Source').toString(),
                          percent: ((s['percent'] ?? 0) as num).toDouble(),
                          count: (s['count'] ?? 0) is num
                              ? ((s['count'] ?? 0) as num).toInt()
                              : 0,
                        ),
                        if (s != a.topSources.last) const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // ── Capacity utilization (kept from the previous board) ───
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: SportXShadows.e1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Capacity Utilization',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          '${a.utilizationPercent}%',
                          style: GoogleFonts.sora(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDarker,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${a.totalRegistered}/${a.totalCapacity} spots filled • ${a.spotsLeft} left',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: a.totalCapacity == 0
                            ? 0
                            : (a.totalRegistered / a.totalCapacity).clamp(0, 1),
                        minHeight: 8,
                        backgroundColor: AppColors.borderSoft,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.yellow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Deadline alert ────────────────────────────────────────
              if (a.deadlineAlert != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.triangleAlert,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${a.deadlineAlert!['tournament_name']} closes in ${a.deadlineAlert!['days_left']} days',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (a.deadlineAlert != null) const SizedBox(height: 16),

              // ── Category breakdown ────────────────────────────────────
              if (a.categoryBreakdown.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: SportXShadows.e1,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capacity by Category',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...a.categoryBreakdown.map((cat) {
                        final cap = (cat['capacity'] ?? 0) as int;
                        final reg = (cat['registered'] ?? 0) as int;
                        final pending = (cat['pending'] ?? 0) as int;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${cat['tournament_name']} • ${cat['category_name']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '$reg/$cap',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: cap == 0 ? 0 : (reg / cap).clamp(0, 1),
                                  minHeight: 6,
                                  backgroundColor: AppColors.borderSoft,
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.yellow,
                                  ),
                                ),
                              ),
                              if (pending > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '$pending pending approval',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.amberDeep,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rangePill(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          color: active ? null : AppColors.surface,
          border: Border.all(
            color: active ? const Color(0x2E785000) : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }

  static const _mon = [
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
    'Dec',
  ];

  /// "2026-10-12" → "12 Oct" for the chart axis labels.
  static String _shortDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day} ${_mon[d.month - 1]}';
  }
}
