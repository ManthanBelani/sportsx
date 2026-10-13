import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/opportunity/presentation/providers/opportunity_provider.dart';
import 'package:sportx_app/features/saved/presentation/providers/saved_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Opportunity detail + apply form D.10 (Phase 4).
class OpportunityDetailScreen extends ConsumerStatefulWidget {
  final String opportunityId;
  const OpportunityDetailScreen({super.key, required this.opportunityId});

  @override
  ConsumerState<OpportunityDetailScreen> createState() => _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends ConsumerState<OpportunityDetailScreen> {
  final _pitchController = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _pitchController.dispose();
    super.dispose();
  }

  bool get _isAthlete => (ref.read(authProvider).user?.role ?? '') == 'athlete';

  Future<void> _apply() async {
    if (_pitchController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Tell the provider why you are a good fit');
      return;
    }
    setState(() => _applying = true);
    try {
      final ok = await ref.read(myOpportunitiesProvider.notifier).apply(
            opportunityId: widget.opportunityId,
            pitch: _pitchController.text.trim(),
          );
      if (!mounted) return;
      if (ok) {
        SnackBarUtils.showSuccess(context, 'Application submitted!');
        ref.invalidate(opportunityDetailProvider(widget.opportunityId));
      } else {
        SnackBarUtils.showError(
          context,
          ref.read(myOpportunitiesProvider).error ?? 'Application failed',
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(opportunityDetailProvider(widget.opportunityId));
    final saved = ref.watch(savedProvider).isSaved('opportunity', widget.opportunityId);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Opportunity',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        actions: [
          IconButton(
            icon: Icon(
              saved ? LucideIcons.heart : LucideIcons.heart,
              color: saved ? AppColors.error : AppColors.textSecondary,
            ),
            onPressed: () => ref.read(savedProvider.notifier).toggle(
              type: 'opportunity',
              itemId: widget.opportunityId,
            ),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const GenericListSkeleton(),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (o) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.yellowTint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(o.type.toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  if (o.amountLabel.isNotEmpty)
                    Text(o.amountLabel,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),
              Text(o.title,
                  style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
              if (o.deadline != null) ...[
                const SizedBox(height: 6),
                Text('Apply by ${o.deadline!.day}/${o.deadline!.month}/${o.deadline!.year}',
                    style: const TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w600)),
              ],
              if (o.description != null && o.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(o.description!, style: const TextStyle(fontSize: 14, height: 1.5)),
              ],
              if (o.eligibility != null && o.eligibility!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Eligibility',
                    style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(o.eligibility!, style: const TextStyle(fontSize: 14)),
              ],
              if (o.benefits != null && o.benefits!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Benefits',
                    style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(o.benefits!, style: const TextStyle(fontSize: 14)),
              ],
              const SizedBox(height: 24),
              if (_isAthlete)
                o.applied
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Applied${o.applicationStatus != null ? ' · ${o.applicationStatus}' : ''}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Your pitch',
                            style: GoogleFonts.sora(
                                fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pitchController,
                          maxLines: 4,
                          maxLength: 2000,
                          decoration: const InputDecoration(
                            hintText: 'Why are you a good fit for this opportunity?',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _applying
                            ? const Center(child: CircularProgressIndicator())
                            : PrimaryButton(
                                label: 'Apply Now',
                                icon: LucideIcons.send,
                                onPressed: _apply,
                              ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
