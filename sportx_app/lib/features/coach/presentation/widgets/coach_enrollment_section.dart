import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/coach/presentation/providers/coaching_enrollment_provider.dart';
import 'package:sportx_app/shared/models/approval.dart';
import 'package:sportx_app/shared/models/coach.dart';
import 'package:sportx_app/theme/colors.dart';

/// Enrollment section shown on the coach detail screen when the coach
/// offers personal coaching (docs/Approval-Based-Registration-System.md §6.6).
class CoachEnrollmentSection extends ConsumerStatefulWidget {
  final Coach coach;
  const CoachEnrollmentSection({super.key, required this.coach});

  @override
  ConsumerState<CoachEnrollmentSection> createState() => _CoachEnrollmentSectionState();
}

class _CoachEnrollmentSectionState extends ConsumerState<CoachEnrollmentSection> {
  bool _submitting = false;

  bool get _isAthlete => ref.watch(authProvider).user?.role == 'athlete';

  Future<void> _onEnroll() async {
    final plan = await showModalBottomSheet<PlanType>(
      context: context,
      builder: (context) => _PlanSelectionSheet(coach: widget.coach),
    );
    if (plan == null || !mounted) return;

    final notesController = TextEditingController();
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enrollment Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add a note to your coach (optional):'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Introduce yourself and your goals...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, notesController.text.trim()),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
    if (notes == null || !mounted) return;

    setState(() => _submitting = true);
    final (ok, error) = await ref
        .read(coachingEnrollmentActionsProvider)
        .enroll(coachId: widget.coach.id, planType: plan.name, notes: notes);
    if (mounted) {
      setState(() => _submitting = false);
      if (ok) {
        SnackBarUtils.showSuccess(context, 'Enrollment request submitted!');
      } else {
        SnackBarUtils.showError(context, error ?? 'Failed to submit enrollment request. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coach = widget.coach;
    if (!coach.personalCoaching || !_isAthlete) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Coaching Plans',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (coach.feePerSession != null)
            _priceRow('Per Session', '₹${coach.feePerSession!.toStringAsFixed(0)}'),
          if (coach.feeMonthly != null)
            _priceRow('Monthly', '₹${coach.feeMonthly!.toStringAsFixed(0)}'),
          if (coach.feeQuarterly != null)
            _priceRow('Quarterly', '₹${coach.feeQuarterly!.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          const Text('Approval required before enrollment',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _onEnroll,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(_submitting ? 'Submitting...' : 'Enroll with Coach'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PlanSelectionSheet extends StatelessWidget {
  final Coach coach;
  const _PlanSelectionSheet({required this.coach});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Plan', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (coach.feePerSession != null)
              ListTile(
                title: const Text('Per Session'),
                subtitle: Text('₹${coach.feePerSession!.toStringAsFixed(0)}'),
                onTap: () => Navigator.pop(context, PlanType.session),
              ),
            if (coach.feeMonthly != null)
              ListTile(
                title: const Text('Monthly'),
                subtitle: Text('₹${coach.feeMonthly!.toStringAsFixed(0)}'),
                trailing: const Chip(label: Text('Popular')),
                onTap: () => Navigator.pop(context, PlanType.monthly),
              ),
            if (coach.feeQuarterly != null)
              ListTile(
                title: const Text('Quarterly'),
                subtitle: Text('₹${coach.feeQuarterly!.toStringAsFixed(0)}'),
                onTap: () => Navigator.pop(context, PlanType.quarterly),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
