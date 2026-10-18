import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_sheets.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// A.10 Verification Request & Status — apply for the blue check and track it.
/// States: none → pending → verified / rejected.
enum _VerifyStatus { none, pending, verified, rejected }

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  _VerifyStatus _status = _VerifyStatus.none;
  final _proof = TextEditingController();
  bool _idUploaded = false;
  bool _orgUploaded = false;

  @override
  void dispose() {
    _proof.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Verification', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _statusCard(),
          const SizedBox(height: 16),
          if (_status == _VerifyStatus.none ||
              _status == _VerifyStatus.rejected) ...[
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
                            onTap: () =>
                                setState(() => _idUploaded = true),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 96,
                          child: MediaUploadTile(
                            label: 'Org proof',
                            onTap: () =>
                                setState(() => _orgUploaded = true),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _proof,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Anything else we should know? (optional)',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Submit for verification',
                icon: LucideIcons.send,
                onPressed: (_idUploaded && _orgUploaded)
                    ? () => setState(() => _status = _VerifyStatus.pending)
                    : null,
              ),
            ),
            if (!(_idUploaded && _orgUploaded)) ...[
              const SizedBox(height: 10),
              Text('Upload both documents to continue.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: AppColors.textSecondary)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _statusCard() {
    late StatusPill pill;
    late IconData icon;
    late Color tint;
    late String title;
    late String message;

    switch (_status) {
      case _VerifyStatus.verified:
        pill = const StatusPill(label: 'VERIFIED', kind: PillKind.ok);
        icon = LucideIcons.badgeCheck;
        tint = AppColors.success;
        title = 'You\'re verified';
        message = 'Your blue check is live on your profile.';
      case _VerifyStatus.pending:
        pill = const StatusPill(label: 'PENDING', kind: PillKind.pending);
        icon = LucideIcons.clock;
        tint = AppColors.warning;
        title = 'Under review';
        message = 'We usually review requests within 24–48 hours.';
      case _VerifyStatus.rejected:
        pill = const StatusPill(label: 'ACTION NEEDED', kind: PillKind.no);
        icon = LucideIcons.x;
        tint = AppColors.error;
        title = 'Couldn\'t verify';
        message = 'The documents were unclear. Please re-upload.';
      case _VerifyStatus.none:
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
                  Text(title,
                      style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
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
                                fontSize: 12,
                                color: AppColors.textSecondary)),
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
