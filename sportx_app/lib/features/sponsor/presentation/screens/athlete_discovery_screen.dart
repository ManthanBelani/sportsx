import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class AthleteDiscoveryScreen extends ConsumerWidget {
  const AthleteDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(athletesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Discover Athletes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('Sport'),
                const SizedBox(width: 8),
                _buildFilterChip('Age'),
                const SizedBox(width: 8),
                _buildFilterChip('City'),
                const SizedBox(width: 8),
                _buildFilterChip('Level'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(athletesProvider),
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$e', style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(athletesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (athletes) => athletes.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 200),
                        Center(child: Text('No athletes found', style: TextStyle(color: AppColors.textSecondary))),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: athletes.length,
                        itemBuilder: (context, i) {
                          final a = athletes[i];
                          final id = a['id']?.toString() ?? '';
                          final name = a['name'] ?? a['full_name'] ?? 'Athlete';
                          final sportRaw = a['sport'];
                          final sport = sportRaw is Map ? sportRaw['name'] : sportRaw;
                          final cityRaw = a['city'];
                          final city = cityRaw is Map ? cityRaw['name'] : cityRaw;
                          final subtitle = [sport, a['age_group_label'], city]
                              .whereType<String>()
                              .where((s) => s.isNotEmpty)
                              .join(' · ');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildAthleteCard(context, id, name.toString(), subtitle),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
    );
  }

  Widget _buildAthleteCard(BuildContext context, String id, String name, String subtitle) {
    return InkWell(
      onTap: () => context.push('/athlete-profile-view', extra: {'id': id}),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(LucideIcons.user, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/athlete-profile-view', extra: {'id': id}),
              child: const Text('View →'),
            ),
          ],
        ),
      ),
    );
  }
}
