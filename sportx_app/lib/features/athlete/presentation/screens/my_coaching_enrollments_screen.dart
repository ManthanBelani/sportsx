import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/features/coach/presentation/providers/coaching_enrollment_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class MyCoachingEnrollmentsScreen extends ConsumerWidget {
  const MyCoachingEnrollmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCoachingEnrollmentsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('My Coaching Enrollments',
            style: GoogleFonts.sora(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(LucideIcons.graduationCap, size: 64, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text('No coaching enrollments yet',
                  style: GoogleFonts.sora(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const Text('Browse coaches and request enrollment',
                  style: TextStyle(color: AppColors.textTertiary)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final e = items[index];
              final color = switch (e.approvalStatus) {
                'approved' => AppColors.success,
                'rejected' => AppColors.error,
                _ => AppColors.warning
              };
              final kind = switch (e.approvalStatus) {
                'approved' => PillKind.ok,
                'rejected' => PillKind.no,
                _ => PillKind.pending
              };
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.yellowTint, AppColors.yellow, AppColors.ctaDark],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.user, color: AppColors.ink, size: 22),
                  ),
                  title: Text(e.coach?.fullName ?? 'Coach #${e.coachId}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${e.planType.name} • ₹${e.feesAmount.toStringAsFixed(0)}'),
                    const SizedBox(height: 6),
                    StatusPill(label: e.approvalStatus, kind: kind),
                    if (e.isRejected && e.rejectionReason != null)
                      Text(e.rejectionReason!,
                          style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  ]),
                  trailing: Icon(
                      e.isApproved
                          ? LucideIcons.circleCheck
                          : e.isRejected
                              ? LucideIcons.circleX
                              : LucideIcons.hourglass,
                      color: color),
                ),
              );
            },
          );
        },
        loading: () => const GenericListSkeleton(itemCount: 5),
        error: (e, _) => Center(child: Text(ApiException.messageFor(e))),
      ),
    );
  }
}
