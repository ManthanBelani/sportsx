import 'package:flutter/material.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/sponsor/presentation/providers/sponsor_provider.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class AthleteProfileViewScreen extends ConsumerWidget {
  final String athleteId;
  const AthleteProfileViewScreen({super.key, required this.athleteId});

  String _sportLabel(Map<String, dynamic> a) {
    final sportRaw = a['sport'];
    return sportRaw is Map ? (sportRaw['name'] ?? '') : (sportRaw ?? '').toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (athleteId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Athlete')),
        body: const Center(child: Text('Athlete not found')),
      );
    }
    final async = ref.watch(athleteDetailProvider(athleteId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: async.maybeWhen(data: (a) => Text(a['name'] ?? a['full_name'] ?? 'Athlete'), orElse: () => const Text('Athlete')),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: async.when(
        loading: () => const GenericDetailSkeleton(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ApiException.messageFor(e), style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Retry',
                icon: LucideIcons.refreshCw,
                onPressed: () => ref.invalidate(athleteDetailProvider(athleteId)),
              ),
            ],
          ),
        ),
        data: (a) {
          final name = (a['name'] ?? a['full_name'] ?? 'Athlete').toString();
          final achievements = (a['achievements'] as List? ?? []).cast<Map<String, dynamic>>();
          final media = (a['media'] as List? ?? []).cast<Map<String, dynamic>>();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFE9A8), Color(0xFFFFC107), Color(0xFFF5B400)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.yellowTint,
                      child: Icon(LucideIcons.user, size: 46, color: AppColors.ink)),
                ),
                const SizedBox(height: 12),
                Text(name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(_sportLabel(a), style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Achievements', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                if (achievements.isEmpty)
                  const ListTile(contentPadding: EdgeInsets.zero, title: Text('No achievements listed'))
                else
                  ...achievements.map((ach) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(LucideIcons.trophy, color: Colors.amber),
                        title: Text((ach['title'] ?? ach['name'] ?? '').toString()),
                      )),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Media Gallery', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: media.isEmpty
                      ? const Center(child: Text('No media', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: media.length,
                          itemBuilder: (context, i) => Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(LucideIcons.image, color: AppColors.textSecondary),
                          ),
                        ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Shortlist',
                        icon: LucideIcons.star,
                        onPressed: () async {
                          final ok = await ref.read(shortlistProvider.notifier).add(athleteId);
                          if (context.mounted) {
                            if (ok) {
  SnackBarUtils.showSuccess(context, 'Added to Shortlist');
} else {
  SnackBarUtils.showError(context, 'Already shortlisted or failed');
}
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}