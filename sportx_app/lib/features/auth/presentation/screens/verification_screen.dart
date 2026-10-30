import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/verification_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/media_picker.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_sheets.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// A.10 Verification Request & Status — apply for the blue check and track it.
/// States: none → pending → verified / rejected. Backed by
/// POST/GET /me/verification via [verificationProvider].
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() =>
      _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _notesController = TextEditingController();
  bool _idUploading = false;
  bool _orgUploading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(verificationProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDoc({required bool isId}) async {
    setState(
        () => isId ? _idUploading = true : _orgUploading = true);
    try {
      final picked = await pickAndUploadMedia(
        context,
        ref,
        mediaType: 'document',
        uploadContext: 'credential',
      );
      final mediaId = picked?.mediaId;
      if (mediaId != null) {
        ref.read(verificationProvider.notifier).addProof(mediaId);
      }
    } finally {
      if (mounted) {
        setState(() => isId ? _idUploading = false : _orgUploading = false);
      }
    }
  }

  Future<void> _submit() async {
    final ok =
        await ref.read(verificationProvider.notifier).submit(_notesController.text);
    if (!mounted) return;
    if (ok) {
      SnackBarUtils.showSuccess(
          context, 'Submitted — review usually takes 24–48 hours.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationProvider);

    final canSubmitMore = state.status == VerifyBadgeStatus.none ||
        state.status == VerifyBadgeStatus.rejected;
    final canOpenDocs = state.proofIds.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Verification', showBack: true),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.yellowDeep))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _statusCard(state),
                const SizedBox(height: 16),
                if (canSubmitMore) ...[
                  _requirements(),
                  const SizedBox(height: 16),
                  SportXCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Documents',
                            style: GoogleFonts.sora(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 96,
                                child: MediaUploadTile(
                                  label: 'Government ID',
                                  isUploading: _idUploading,
                                  onTap: () => _pickDoc(isId: true),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 96,
                                child: MediaUploadTile(
                                  label: 'Org proof',
                                  isUploading: _orgUploading,
                                  onTap: () => _pickDoc(isId: false),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (state.proofIds.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final id in state.proofIds)
                                InputChip(
                                  avatar: const Icon(LucideIcons.fileImage,
                                      size: 16, color: AppColors.success),
                                  label: Text('Proof #$id',
                                      style: GoogleFonts.inter(fontSize: 12)),
                                  onDeleted: () => ref
                                      .read(verificationProvider.notifier)
                                      .removeProof(id),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText:
                                'Anything else we should know? (optional)',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(state.error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 12.5, color: AppColors.error)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: state.submitting
                          ? 'Submitting…'
                          : 'Submit for verification',
                      icon: LucideIcons.send,
                      onPressed:
                          (canOpenDocs && !state.submitting) ? _submit : null,
                    ),
                  ),
                  if (!canOpenDocs) ...[
                    const SizedBox(height: 10),
                    Text('Upload at least one proof document to continue.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.textSecondary)),
                  ],
                ],
              ],
            ),
    );
  }

  Widget _statusCard(VerificationState state) {
    late StatusPill pill;
    late IconData icon;
    late Color tint;
    late String title;
    String message;

    switch (state.status) {
      case VerifyBadgeStatus.verified:
        pill = const StatusPill(label: 'VERIFIED', kind: PillKind.ok);
        icon = LucideIcons.badgeCheck;
        tint = AppColors.success;
        title = 'You\'re verified';
        message = 'Your blue check is live on your profile.';
      case VerifyBadgeStatus.pending:
        pill = const StatusPill(label: 'PENDING', kind: PillKind.pending);
        icon = LucideIcons.clock;
        tint = AppColors.warning;
        title = 'Under review';
        message = 'We usually review requests within 24–48 hours.';
      case VerifyBadgeStatus.rejected:
        pill = const StatusPill(label: 'ACTION NEEDED', kind: PillKind.no);
        icon = LucideIcons.x;
        tint = AppColors.error;
        title = 'Couldn\'t verify';
        message = state.decisionReason?.isNotEmpty == true
            ? state.decisionReason!
            : 'The documents were unclear. Please re-upload.';
      case VerifyBadgeStatus.none:
        pill = const StatusPill(label: 'NOT VERIFIED', kind: PillKind.draft);
        icon = LucideIcons.shieldCheck;
        tint = AppColors.textSecondary;
        title = 'Get verified';
        message = 'Verify your identity to build trust and stand out.';
    }

    return SportXCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(title,
                        style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                  ),
                  const SizedBox(width: 8),
                  pill,
                ]),
                const SizedBox(height: 4),
                Text(message,
                    style: GoogleFonts.inter(
                        fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _requirements() {
    const items = [
      ('Government-issued ID', 'Passport, Aadhaar or driving licence'),
      ('Organisation proof', 'Registration cert, letterhead or profile link'),
    ];
    return SportXCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What you\'ll need',
              style: GoogleFonts.sora(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 12),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.circleCheck,
                      size: 18, color: AppColors.verifiedBadge),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.$1,
                            style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                        Text(it.$2,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
