import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/features/coach/presentation/providers/coaching_enrollment_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class CoachEnrollmentScreen extends ConsumerWidget {
  const CoachEnrollmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Enrollment Requests'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            tabs: [Tab(text: 'Pending'), Tab(text: 'Active'), Tab(text: 'Rejected')],
          ),
        ),
        body: const TabBarView(
          children: [
            _EnrollmentListView(filter: 'pending'),
            _EnrollmentListView(filter: 'approved'),
            _EnrollmentListView(filter: 'rejected'),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentListView extends ConsumerWidget {
  final String filter;
  const _EnrollmentListView({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(coachEnrollmentsProvider(filter == 'approved' ? 'approved' : filter));
    return async.when(
      data: (items) {
        if (items.isEmpty) return Center(child: Text('No $filter enrollments'));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final e = items[index];
            return _EnrollmentCard(enrollment: e, filter: filter);
          },
        );
      },
      loading: () => const GenericListSkeleton(itemCount: 4),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _EnrollmentCard extends ConsumerWidget {
  final dynamic enrollment;
  final String filter;
  const _EnrollmentCard({required this.enrollment, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athleteName = enrollment.athlete?['user']?['name'] ?? 'Athlete';
    final status = enrollment.approvalStatus;
    final color = switch (status) { 'approved' => Colors.green, 'rejected' => Colors.red, _ => Colors.orange };

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(athleteName, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(enrollment.planType.name, style: const TextStyle(color: Colors.grey)),
            ])),
            Chip(label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: color),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              Column(children: [const Text('Plan', style: TextStyle(fontSize: 12)), Text(enrollment.planType.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))]),
              Column(children: [const Text('Fees', style: TextStyle(fontSize: 12)), Text('₹${enrollment.feesAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold))]),
            ]),
          ),
          if (enrollment.notes != null && enrollment.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Note: ${enrollment.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
          if (enrollment.isRejected && enrollment.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Text('Reason: ${enrollment.rejectionReason}', style: const TextStyle(color: Colors.red)),
          ],
          if (filter == 'pending') ...[
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(onPressed: () => _reject(context, ref), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('Reject')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () => _approve(context, ref), child: const Text('Approve')),
            ]),
          ],
        ]),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date != null && context.mounted) {
      final ok = await ref.read(coachingEnrollmentActionsProvider).approve(enrollment.id.toString(), startDate: date);
      if (context.mounted) SnackBarUtils.showSuccess(context, ok ? 'Enrollment approved' : 'Failed');
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: const Text('Reject Enrollment'), content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Reason')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Reject'))]));
    if (reason != null && reason.trim().isNotEmpty && context.mounted) {
      final ok = await ref.read(coachingEnrollmentActionsProvider).reject(enrollment.id.toString(), reason.trim());
      if (context.mounted) SnackBarUtils.showSuccess(context, ok ? 'Rejected' : 'Failed');
    }
  }
}
