import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class ApplySponsorScreen extends ConsumerStatefulWidget {
  final String sponsorshipId;
  const ApplySponsorScreen({super.key, required this.sponsorshipId});

  @override
  ConsumerState<ApplySponsorScreen> createState() => _ApplySponsorScreenState();
}

class _ApplySponsorScreenState extends ConsumerState<ApplySponsorScreen> {
  final _pitchNoteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _pitchNoteController.dispose();
    super.dispose();
  }

  Future<void> _submit(Sponsorship sponsorship) async {
    if (_pitchNoteController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter a pitch note');
      return;
    }

    setState(() => _submitting = true);

    try {
      await ref.read(dioProvider).post(
        '/sponsorships/${widget.sponsorshipId}/apply',
        data: {
          'pitch_note': _pitchNoteController.text.trim(),
        },
      );
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Application submitted successfully!');
        context.pop();
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        final apiEx = ApiException.fromDio(e);
        if (apiEx.fieldErrors.isNotEmpty) {
          SnackBarUtils.showValidationError(context, apiEx.fieldErrors, apiEx);
        } else {
          SnackBarUtils.showError(context, apiEx);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e, 'Failed to submit application. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sponsorshipDetailProvider(widget.sponsorshipId));
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SportXTopBar(
        titleWidget: Text(
          'Apply to Sponsor',
          style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: async.when(
        data: (sponsorship) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: SportXShadows.e1,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: sponsorship.sponsorLogoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                sponsorship.sponsorLogoUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  LucideIcons.star,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : const Icon(LucideIcons.star, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sponsorship.sponsorName ?? 'Sponsor',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sponsorship.title,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your Profile (auto-attached)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: user?.profilePhotoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user!.profilePhotoUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  LucideIcons.user,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : const Icon(LucideIcons.user, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Loading...',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Athlete',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your profile with achievements, sports, and media gallery will be shared with the sponsor.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pitch Note (Why should they sponsor you?)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pitchNoteController,
                maxLines: 6,
                enabled: !_submitting,
                decoration: InputDecoration(
                  hintText: 'Hi ${sponsorship.sponsorName ?? 'Sponsor'},\n\nI\'m [Your Name], a [age]-year-old [sport] player from [city]. I\'ve been playing for [years] years and recently [achievement]. I train [frequency] at [academy/club] and dream of [goal].\n\nThis sponsorship would help me access better equipment and training opportunities...',
                  hintStyle: TextStyle(
                    color: AppColors.textTertiary.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Attach Additional Documents (optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 2),
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.surface,
                ),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.upload,
                      size: 32,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+ Upload Certificates / Achievements',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const GenericListSkeleton(),
        error: (e, _) => Center(child: Text(ApiException.messageFor(e))),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (sponsorship) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            child: _submitting
                ? Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink)),
                  )
                : PrimaryButton(
                    label: 'Submit Application',
                    icon: LucideIcons.send,
                    onPressed: () => _submit(sponsorship),
                  ),
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}