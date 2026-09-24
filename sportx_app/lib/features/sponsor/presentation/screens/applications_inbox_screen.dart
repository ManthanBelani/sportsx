import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/date_format_utils.dart';
import 'package:sportx_app/features/sponsor/presentation/providers/sponsor_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class ApplicationsInboxScreen extends ConsumerWidget {
  const ApplicationsInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sponsorApplicationsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text('Applications',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(sponsorApplicationsProvider),
        child: async.when(
          loading: () => const GenericListSkeleton(),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ApiException.messageFor(e), style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Retry',
                  icon: LucideIcons.refreshCw,
                  onPressed: () => ref.invalidate(sponsorApplicationsProvider),
                ),
              ],
            ),
          ),
          data: (apps) => apps.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No applications yet', style: TextStyle(color: AppColors.textSecondary))),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: apps.length,
                  itemBuilder: (context, i) {
                    final a = apps[i];
                    final name = (a['athlete_name'] ?? a['name'] ?? 'Athlete').toString();
                    final sportRaw = a['sport'];
                    final sport = sportRaw is Map ? sportRaw['name'] : sportRaw;
                    final listing = a['sponsorship_title'] ?? 'Sponsorship';
                    final rawDate = a['created_at']?.toString() ?? '';
                    final date = rawDate.isEmpty ? '' : DateFormatUtils.formatRelative(rawDate);
                    final status = (a['status'] ?? 'pending').toString();
                    final isNew = status == 'pending';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildApplicationCard(context, name, sport?.toString() ?? '', listing, date, isNew, a),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(BuildContext context, String name, String sport, String listing,
      String date, bool isNew, Map<String, dynamic> app) {
    return InkWell(
      onTap: () => context.push('/application-detail', extra: {
        'id': app['id']?.toString() ?? '',
        'sponsorship_id': app['sponsorship_id']?.toString() ?? '',
      }),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          color: isNew ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 16, backgroundColor: AppColors.primary, child: Icon(LucideIcons.user, size: 16, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('$name · $sport',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ),
                if (isNew)
                  const StatusPill(label: 'New', kind: PillKind.info),
              ],
            ),
            const SizedBox(height: 8),
            Text('Applied to: $listing', style: const TextStyle(color: AppColors.textSecondary)),
            if (date.toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Date: $date', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
