import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/home_kit.dart';
import 'package:sportx_app/shared/providers/enquiry_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

/// AC.2 Academy dashboard — v3 homeShell + the design's kpi-grid
/// (Enquiries / Registrations from real enquiry + trial data).
class AcademyDashboardScreen extends ConsumerWidget {
  const AcademyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(myAcademyProvider);
    final enquiries = ref.watch(enquiryInboxProvider);
    final trialsState = ref.watch(myTrialsProvider);
    final academy = ref.watch(myAcademyProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.yellowDeep,
        onRefresh: () async {
          ref.invalidate(myAcademyProvider);
          ref.invalidate(enquiryInboxProvider);
          await ref.read(myTrialsProvider.notifier).refresh();
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
                    name: 'Hi, ${academy?.name ?? 'Academy'}!',
                    avatarInitial: _initialOf(academy?.name),
                    avatarUrl: MediaUtils.resolveNullable(academy?.logoUrl),
                    subtitle: 'Keep programs and trials up to date to attract athletes',
                    progress: 0.7,
                    ctaLabel: 'Complete Now',
                    onCta: () => context.push('/edit-academy-profile'),
                  ),
                  const SizedBox(height: 10),
                  const RoleLine(badgeLabel: 'ACADEMY'),
                  const LeaderboardSectionV3(),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.62,
                    children: [
                      QuickTileV3(
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
                      QuickTileV3(
                        title: 'Find Talent',
                        subtitle: 'Connect with Athletes · Coaches · Staff',
                        icon: LucideIcons.users,
                        iconBg: AppColors.infoLight,
                        iconFg: AppColors.info,
                        onTap: () => context.push('/athlete-directory'),
                        subtiles: const [
                          (label: 'Athletes', route: '/athlete-directory'),
                          (label: 'Coaches', route: '/coaches'),
                          (label: 'Staff', route: '/academy-staff'),
                          (label: 'More', route: '/explore'),
                        ],
                      ),
                    ],
                  ),
                  const V3FeedPreview(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _Kpi(
                            value: enquiries.items.length.toString(),
                            label: 'Enquiries',
                            onTap: () => context.push('/enquiry-inbox')),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Kpi(
                            value: trialsState.items.length.toString(),
                            label: 'Registrations',
                            onTap: () => context.push('/my-trials')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 96),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initialOf(String? name) =>
      name != null && name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'A';
}

class _Kpi extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;
  const _Kpi({required this.value, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
