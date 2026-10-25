import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/organizer/presentation/widgets/organizer_kit.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';

/// Design board screen 8 · Event Details & Management — hero banner, date
/// block, title/location, meta row with the "Registrations Open" pill, the
/// Overview / Registrations / Schedule / Gallery tabs, the info rows with the
/// capacity bar, the Share + Promote buttons and the "Manage Event" CTA.
class OrganizerEventManagementScreen extends ConsumerWidget {
  final String tournamentId;
  const OrganizerEventManagementScreen({super.key, required this.tournamentId});

  String _dates(DateTime s, DateTime e) {
    const m = [
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
    if (s.month == e.month && s.year == e.year) {
      return '${s.day} – ${e.day} ${m[s.month - 1]} ${s.year}';
    }
    return '${s.day} ${m[s.month - 1]} – ${e.day} ${m[e.month - 1]} ${e.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tournamentDetailProvider(tournamentId));

    return async.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.surface,
        body: GenericDetailSkeleton(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.surface,
        appBar: SportXTopBar(
          title: 'Event Details',
          showBack: true,
          onBack: () => context.pop(),
        ),
        body: Center(
          child: SecondaryButton(
            label: 'Retry',
            onPressed: () =>
                ref.invalidate(tournamentDetailProvider(tournamentId)),
          ),
        ),
      ),
      data: (t) {
        final totalCapacity = t.totalSpots ?? 0;
        final registered = t.confirmedRegistrationsCount > 0
            ? t.confirmedRegistrationsCount
            : (t.filledSpots ?? t.registrationsCount);
        final fill = totalCapacity > 0
            ? (registered / totalCapacity).clamp(0.0, 1.0)
            : 0.0;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.88),
            surfaceTintColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                LucideIcons.arrowLeft,
                color: AppColors.textPrimary,
              ),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Event Details & Management',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => context.push('/edit-tournament/$tournamentId'),
                icon: const Icon(
                  LucideIcons.pencil,
                  size: 15,
                  color: AppColors.ink,
                ),
                label: Text(
                  'Edit',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.border),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero banner
                Stack(
                  children: [
                    Container(
                      height: 170,
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1B2430), Color(0xFF3A2B14)],
                        ),
                      ),
                      child: (t.bannerUrl ?? '').isNotEmpty
                          ? Image.network(
                              MediaUtils.resolveUrl(t.bannerUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(
                                  LucideIcons.trophy,
                                  size: 54,
                                  color: Color(0x33FFFFFF),
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                LucideIcons.trophy,
                                size: 54,
                                color: Color(0x33FFFFFF),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            LucideIcons.moreVertical,
                            size: 16,
                            color: AppColors.ink,
                          ),
                        ),
                        onSelected: (v) {
                          switch (v) {
                            case 'edit':
                              context.push('/edit-tournament/$tournamentId');
                              break;
                            case 'results':
                              context.push(
                                '/results-publishing',
                                extra: {'id': tournamentId, 'title': t.title},
                              );
                              break;
                            case 'share':
                              Share.share('${t.title} — ${t.venue ?? ''}');
                              break;
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit event'),
                          ),
                          PopupMenuItem(
                            value: 'results',
                            child: Text('Publish results'),
                          ),
                          PopupMenuItem(value: 'share', child: Text('Share')),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OrgDateBlock(
                            start: t.startDate,
                            end: t.endDate,
                            width: 58,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.mapPin,
                                      size: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        [t.venue, t.city?.name]
                                            .whereType<String>()
                                            .where((s) => s.isNotEmpty)
                                            .join(', '),
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          final sportName = t.sport?.name;
                          final ageLabel = t.ageGroupLabel;
                          return Row(
                            children: [
                              // Flexible clamp: sport + age + status pills can
                              // exceed the card width together — without the
                              // clamps this row overflowed on the right.
                              if (sportName != null && sportName.isNotEmpty)
                                Flexible(
                                  child: OrgPill(sportName, kind: OrgPillKind.info),
                                ),
                              if (ageLabel != null && ageLabel.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: OrgPill(ageLabel, kind: OrgPillKind.draft),
                                ),
                              ],
                              const Spacer(),
                              if (t.status == 'published' ||
                                  t.status == 'active')
                                const OrgPill(
                                  'Registrations Open',
                                  kind: OrgPillKind.open,
                                  dot: true,
                                )
                              else
                                OrgPill(
                                  t.status.toUpperCase(),
                                  kind: OrgPillKind.draft,
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Overview rows
                      _InfoRow(
                        icon: LucideIcons.calendar,
                        text: t.startDate != null && t.endDate != null
                            ? _dates(t.startDate!, t.endDate!)
                            : (t.startDate != null
                                  ? '${t.startDate!.day}/${t.startDate!.month}/${t.startDate!.year}'
                                  : 'Dates TBA'),
                      ),
                      _InfoRow(
                        icon: LucideIcons.mapPin,
                        text: [t.venue, t.city?.name]
                            .whereType<String>()
                            .where((s) => s.isNotEmpty)
                            .join(', '),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(
                              icon: LucideIcons.users,
                              text: totalCapacity > 0
                                  ? '$registered Registered ($totalCapacity slots)'
                                  : '$registered Registered',
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 27),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: fill,
                                  minHeight: 7,
                                  backgroundColor: AppColors.borderSoft,
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.yellow,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (t.registrationFee != null && t.registrationFee! > 0)
                        _InfoRow(
                          icon: LucideIcons.indianRupee,
                          text:
                              '₹${t.registrationFee!.toStringAsFixed(0)} / team',
                        ),
                      const SizedBox(height: 6),

                      // Share + Promote
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: 'Share',
                              icon: LucideIcons.share2,
                              onPressed: () =>
                                  Share.share('${t.title} — ${t.venue ?? ''}'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SecondaryButton(
                              label: 'Promote',
                              icon: LucideIcons.megaphone,
                              onPressed: () => context.push('/create-post'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: 'Manage Event',
                          icon: LucideIcons.settings2,
                          onPressed: () => context.push(
                            '/registration-management',
                            extra: {'id': tournamentId, 'title': t.title},
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Quick links to the other management surfaces
                      Row(
                        children: [
                          Expanded(
                            child: _QuickLink(
                              icon: LucideIcons.users,
                              label: 'Registrations',
                              onTap: () => context.push(
                                '/registration-management',
                                extra: {'id': tournamentId, 'title': t.title},
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickLink(
                              icon: LucideIcons.layoutGrid,
                              label: 'Capacity',
                              onTap: () => context.push(
                                '/capacity-management',
                                extra: {'id': tournamentId},
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickLink(
                              icon: LucideIcons.trophy,
                              label: 'Results',
                              onTap: () => context.push(
                                '/results-publishing',
                                extra: {'id': tournamentId, 'title': t.title},
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryDarker),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
          boxShadow: SportXShadows.e1,
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: AppColors.primaryDarker),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
