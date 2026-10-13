import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/features/program/presentation/providers/program_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Program directory (Phase 5): browse active training programs.
class ProgramListScreen extends ConsumerWidget {
  const ProgramListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(programsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        title: Text('Programs',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: state.isLoading && state.items.isEmpty
          ? const GenericListSkeleton()
          : RefreshIndicator(
              onRefresh: () => ref.read(programsProvider.notifier).refresh(),
              child: state.items.isEmpty
                  ? const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: 300,
                        child: Center(child: Text('No programs yet')),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.items.length,
                      itemBuilder: (context, i) {
                        final p = state.items[i];
                        return EntityRow(
                          title: p.title,
                          subtitle: [
                            if (p.sportName != null) p.sportName!,
                            p.mode,
                            p.priceLabel,
                          ].join(' · '),
                          avatarText: p.title.isNotEmpty ? p.title[0].toUpperCase() : 'P',
                          onTap: () => context.push('/program-detail/${p.id}'),
                        );
                      },
                    ),
            ),
    );
  }
}
