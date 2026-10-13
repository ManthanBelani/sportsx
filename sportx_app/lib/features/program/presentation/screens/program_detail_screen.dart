import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/program/presentation/providers/program_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Program detail (Phase 5) with an Enquire button opening a chat thread.
class ProgramDetailScreen extends ConsumerWidget {
  final String programId;
  const ProgramDetailScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(programDetailProvider(programId));
    final role = ref.watch(authProvider).user?.role ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Program',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: detail.when(
        loading: () => const GenericListSkeleton(),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (p) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.title,
                  style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 8),
              Text(
                [
                  if (p.sportName != null) p.sportName!,
                  p.mode,
                  if (p.duration != null) p.duration!,
                ].join(' · '),
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(p.priceLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
              if (p.about != null && p.about!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(p.about!, style: const TextStyle(fontSize: 14, height: 1.5)),
              ],
              if (p.schedule != null && p.schedule!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Schedule',
                    style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(p.schedule!, style: const TextStyle(fontSize: 14)),
              ],
              const SizedBox(height: 24),
              if (role == 'athlete')
                PrimaryButton(
                  label: 'Enquire Now',
                  icon: LucideIcons.messageCircle,
                  onPressed: () => context.push(
                    '/enquire/program/${p.id}/${Uri.encodeComponent(p.title)}',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
