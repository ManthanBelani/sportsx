import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/coach/presentation/providers/coach_provider.dart';
import 'package:sportx_app/shared/providers/enquiry_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/home_kit.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

/// CO.2 Coach dashboard — v3 homeShell('Hi, Coach …', 'COACH', …) ending with
/// the design's "Recent enquiries" list. Providers/routes unchanged.
class CoachDashboardScreen extends ConsumerStatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(coachProvider.notifier).loadCoachProfile();
      ref.read(enquiryInboxProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final coachState = ref.watch(coachProvider);
    final coach = coachState.coachProfile;
    final firstName = coach?.fullName.split(' ').first ?? 'Coach';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.yellowDeep,
        onRefresh: () async {
          ref.read(enquiryInboxProvider.notifier).load();
          await ref.read(coachProvider.notifier).loadCoachProfile();
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
                    name: 'Hi, $firstName!',
                    avatarInitial: firstName.isNotEmpty ? firstName[0].toUpperCase() : 'C',
                    avatarUrl: MediaUtils.resolveNullable(coach?.profilePhotoUrl),
                    subtitle: 'Complete your profile to appear in athlete searches',
                    progress: coach != null && coachState.certifications.isNotEmpty ? 0.75 : 0.5,
                    ctaLabel: 'Complete Now',
                    onCta: () => context.push('/coach-profile-edit'),
                  ),
                  const SizedBox(height: 10),
                  const RoleLine(badgeLabel: 'COACH'),
                  const LeaderboardSectionV3(),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: QuickTileV3(
                            title: 'Opportunities',
                            subtitle: 'Trials · Tournaments · Scholarships · Sponsorships',
                            icon: LucideIcons.trophy,
                            iconBg: AppColors.yellowTint,
                            iconFg: AppColors.primaryDarker,
                            onTap: () => context.push('/opportunities'),
                            subtiles: const [
                              (label: 'Trials', route: '/trials'),
                              (label: 'Tournaments', route: '/tournaments'),
                              (label: 'Scholarships', route: '/scholarships'),
                              (label: 'Sponsors', route: '/sponsorships'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: QuickTileV3(
                            title: 'Academy, Coach & Training Centre',
                            subtitle: 'Find Academies · Athletes · Training Centres',
                            icon: LucideIcons.school,
                            iconBg: AppColors.infoLight,
                            iconFg: AppColors.info,
                            onTap: () => context.push('/academies'),
                            subtiles: const [
                              (label: 'Academies', route: '/academies'),
                              (label: 'Athletes', route: '/athlete-directory'),
                              (label: 'Training', route: '/my-programs'),
                              (label: 'More', route: '/explore'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const V3FeedPreview(),
                  const _EnrollmentsCard(),
                  _EnquiriesCard(state: ref.watch(enquiryInboxProvider)),
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

// ────────────────────────────────────────────────────────────────────────────
// Enrollment requests — entry point for the coach's approve/reject flow
// (/coach-enrollments), which previously had no inbound navigation.
// ────────────────────────────────────────────────────────────────────────────

class _EnrollmentsCard extends StatelessWidget {
  const _EnrollmentsCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/coach-enrollments'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.fromLTRB(2, 10, 2, 0),
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.yellowTint,
              ),
              child: const Icon(LucideIcons.userCheck, size: 18, color: AppColors.primaryDarker),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enrollment requests',
                      style: GoogleFonts.sora(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text('Approve or reject athletes who want to enroll with you.',
                      style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Recent enquiries — CO.2 trailing .prog-list module
// ────────────────────────────────────────────────────────────────────────────

class _EnquiriesCard extends StatelessWidget {
  final EnquiryState state;
  const _EnquiriesCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(2, 10, 2, 0),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 6),
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
            children: [
              Expanded(
                child: Text('Recent enquiries',
                    style: GoogleFonts.sora(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              GestureDetector(
                onTap: () => context.push('/coach-enquiry-inbox'),
                behavior: HitTestBehavior.opaque,
                child: Text('View all ›',
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryDarker)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (state.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No new enquiries — new coaching requests will appear here.',
                  style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary)),
            )
          else
            ...state.items.take(3).map((e) => _EnquiryRow(enquiry: e)),
        ],
      ),
    );
  }
}

class _EnquiryRow extends StatelessWidget {
  final Enquiry enquiry;
  const _EnquiryRow({required this.enquiry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enquiry.isRead ? AppColors.border : AppColors.yellow,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${enquiry.athleteName}: ${enquiry.subject}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(enquiry.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/coach-enquiry-detail', extra: {'id': enquiry.id}),
            child: Text('Reply',
                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.primaryDarker)),
          ),
        ],
      ),
    );
  }
}
