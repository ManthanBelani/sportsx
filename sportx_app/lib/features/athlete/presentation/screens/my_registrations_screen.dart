import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/providers/registration_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class MyRegistrationsScreen extends ConsumerWidget {
  const MyRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Registrations'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            tabs: [Tab(text: 'Tournaments'), Tab(text: 'Trials')],
          ),
        ),
        body: const TabBarView(
          children: [
            _RegistrationsListView(isTournament: true),
            _RegistrationsListView(isTournament: false),
          ],
        ),
      ),
    );
  }
}

class _RegistrationsListView extends ConsumerWidget {
  final bool isTournament;
  const _RegistrationsListView({required this.isTournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = isTournament ? ref.watch(myTournamentRegistrationsProvider) : ref.watch(myTrialRegistrationsProvider);
    return async.when(
      loading: () => const GenericListSkeleton(itemCount: 5),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) return const Center(child: Text('No registrations yet'));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final reg = items[index];
            final name = (reg['tournament']?['name'] ?? reg['trial']?['name'] ?? 'Event').toString();
            final category = (reg['category']?['name'] ?? reg['playing_role'] ?? '').toString();
            final approvalStatus = (reg['approval_status'] ?? reg['status'] ?? 'pending').toString();
            final rejectionReason = reg['rejection_reason']?.toString();
            final color = switch (approvalStatus) {
              'approved' => Colors.green,
              'rejected' => Colors.red,
              _ => Colors.orange,
            };
            final icon = switch (approvalStatus) {
              'approved' => Icons.check_circle,
              'rejected' => Icons.cancel,
              _ => Icons.hourglass_empty,
            };
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (category.isNotEmpty) Text('Category: $category'),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(approvalStatus, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: color,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (approvalStatus == 'rejected' && rejectionReason != null) Text('Reason: $rejectionReason', style: const TextStyle(color: Colors.red, fontSize: 12)),
                ]),
                trailing: Icon(icon, color: color),
              ),
            );
          },
        );
      },
    );
  }
}
