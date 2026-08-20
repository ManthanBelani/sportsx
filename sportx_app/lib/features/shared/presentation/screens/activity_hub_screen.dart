import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/activity_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class ActivityHubScreen extends ConsumerWidget {
  const ActivityHubScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'registered':
      case 'approved':
      case 'verified':
      case 'published':
        return AppColors.success;
      case 'pending':
      case 'draft':
        return AppColors.warning;
      case 'rejected':
      case 'closed':
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityProvider);
    final byCategory = {
      'trial': state.items.where((e) => e.category == 'trial').toList(),
      'tournament': state.items.where((e) => e.category == 'tournament').toList(),
      'sponsorship': state.items.where((e) => e.category == 'sponsorship').toList(),
      'enquiry': state.items.where((e) => e.category == 'enquiry').toList(),
    };

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text('My Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            isScrollable: true,
            tabs: [
              Tab(text: 'Trials'),
              Tab(text: 'Tournaments'),
              Tab(text: 'Sponsorships'),
              Tab(text: 'Enquiries'),
            ],
          ),
        ),
        body: state.isLoading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                children: [
                  _buildList(context, ref, byCategory['trial']!),
                  _buildList(context, ref, byCategory['tournament']!),
                  _buildList(context, ref, byCategory['sponsorship']!),
                  _buildList(context, ref, byCategory['enquiry']!),
                ],
              ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<ActivityEntry> items) {
    if (items.isEmpty) {
      return Center(
        child: Text('No activity yet', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(activityProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          final color = _statusColor(item.status);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      if (item.date != null)
                        Text(item.date!, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(item.status,
                      style: TextStyle(color: color, fontSize: 12)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
