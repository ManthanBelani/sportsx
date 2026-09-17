import 'package:flutter/material.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/features/coach/presentation/providers/coaching_enrollment_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class MyCoachingEnrollmentsScreen extends ConsumerWidget {
  const MyCoachingEnrollmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCoachingEnrollmentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Coaching Enrollments')),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.school_outlined, size: 64, color: Colors.grey), SizedBox(height: 16), Text('No coaching enrollments yet'), Text('Browse coaches and request enrollment', style: TextStyle(color: Colors.grey))]));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final e = items[index];
              final color = switch (e.approvalStatus) { 'approved' => Colors.green, 'rejected' => Colors.red, _ => Colors.orange };
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(e.coach?.fullName ?? 'Coach #${e.coachId}'),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${e.planType.name} • ₹${e.feesAmount.toStringAsFixed(0)}'),
                    const SizedBox(height: 4),
                    Chip(label: Text(e.approvalStatus, style: const TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: color, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    if (e.isRejected && e.rejectionReason != null) Text(e.rejectionReason!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ]),
                  trailing: Icon(e.isApproved ? Icons.check_circle : e.isRejected ? Icons.cancel : Icons.hourglass_empty, color: color),
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
