import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_connection_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
import 'package:sportx_app/theme/colors.dart';

class TalentScoutConnectionsScreen extends ConsumerWidget {
  const TalentScoutConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scoutConnectionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('My Connections',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.pop()),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.border),
                      const SizedBox(height: 16),
                      Text(state.error!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.read(scoutConnectionProvider.notifier).load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.connections.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.users, size: 48, color: AppColors.border),
                          SizedBox(height: 16),
                          Text('No connections yet',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(scoutConnectionProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.connections.length,
                        itemBuilder: (context, index) {
                          final conn = state.connections[index];
                          return _buildConnectionItem(conn);
                        },
                      ),
                    ),
    );
  }

  Widget _buildConnectionItem(Map<String, dynamic> conn) {
    final athlete = conn['athlete'] as Map<String, dynamic>?;
    final photoUrl = athlete?['photo']?['url'] as String?;
    final status = conn['status'] ?? 'pending';

    Color badgeColor;
    Color badgeText;
    switch (status) {
      case 'accepted':
        badgeColor = const Color(0xFFd1fae5);
        badgeText = const Color(0xFF065f46);
        break;
      case 'rejected':
        badgeColor = const Color(0xFFfee2e2);
        badgeText = const Color(0xFF991b1b);
        break;
      default:
        badgeColor = const Color(0xFFfef3c7);
        badgeText = const Color(0xFF92400E);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          AthleteAvatar(photoUrl: photoUrl, radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(athlete?['user']?['name'] ?? 'Athlete',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)),
                  child: Text(status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeText)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
