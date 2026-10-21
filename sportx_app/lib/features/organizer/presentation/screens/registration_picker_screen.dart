import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Entry point for the organizer "Registrations" tile.
///
/// The registration screen itself is per tournament, so this hub lets the
/// organizer pick the tournament they want to work with instead of opening a
/// screen with no tournament loaded.
class RegistrationPickerScreen extends ConsumerWidget {
  const RegistrationPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myTournamentsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Registrations',
            style: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(myTournamentsProvider.notifier).refresh(),
        child: state.isLoading && state.items.isEmpty
            ? const GenericListSkeleton()
            : state.items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 160),
                      Center(
                        child: Text('No tournaments yet',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      Text(
                        'Select a tournament to review its registrations.',
                        style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ...state.items.map((t) {
                        final confirmed = t.confirmedRegistrationsCount;
                        final requests = t.registrationsCount;
                        final clicks = t.externalRegistrationClicks;
                        final external = t.hasExternalRegistration;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: SportXShadows.e1,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.push('/registration-management', extra: {
                              'id': t.id.toString(),
                              'title': t.title,
                            }),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.yellowTint,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(LucideIcons.trophy,
                                        size: 20, color: AppColors.warnText),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink)),
                                        const SizedBox(height: 2),
                                        Text(
                                          external
                                              ? 'External page • $clicks link clicks'
                                              : '$confirmed confirmed • $requests requests',
                                          style: GoogleFonts.inter(
                                              fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(LucideIcons.chevronRight,
                                      size: 18, color: AppColors.textTertiary),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
      ),
    );
  }
}
