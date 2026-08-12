import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/sponsor/presentation/providers/sponsor_provider.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: async.maybeWhen(data: (a) => Text(a['name'] ?? a['full_name'] ?? 'Athlete'), orElse: () => const Text('Athlete')),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(athleteDetailProvider(athleteId)),
                child: const Text('Retry'),
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
                const CircleAvatar(radius: 50, backgroundColor: AppColors.primary, child: Icon(LucideIcons.user, size: 50, color: Colors.white)),
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
                              borderRadius: BorderRadius.circular(8),
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
                      child: FilledButton.icon(
                        onPressed: () async {
                          final ok = await ref.read(shortlistProvider.notifier).add(athleteId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ok ? 'Added to Shortlist' : 'Already shortlisted or failed')),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        icon: const Icon(LucideIcons.star),
                        label: const Text('Shortlist'),
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
