import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class AthleteDiscoveryScreen extends ConsumerWidget {
  const AthleteDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(athletesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text('Discover Athletes',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
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
                loading: () => const DiscoverSkeleton(),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ApiException.messageFor(e), style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Retry',
                        icon: LucideIcons.refreshCw,
                        onPressed: () => ref.invalidate(athletesProvider),
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
    return SportXChip(label: label);
  }

  Widget _buildAthleteCard(BuildContext context, String id, String name, String subtitle) {
    return EntityRow(
      title: name,
      subtitle: subtitle,
      avatarText: name.isNotEmpty ? name[0].toUpperCase() : 'A',
      onTap: () => context.push('/athlete-profile-view', extra: {'id': id}),
    );
  }
}
