import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';

/// Detail view for one verification request: notes + the submitted proof
/// documents resolved through `/media/{id}/signed-url` (admin is allowed by
/// `MediaController::signedUrl`), same pattern as user_detail_verify_screen.
class VerificationRequestDocsScreen extends ConsumerStatefulWidget {
  final VerificationRequestItem request;

  const VerificationRequestDocsScreen({super.key, required this.request});

  @override
  ConsumerState<VerificationRequestDocsScreen> createState() =>
      _VerificationRequestDocsScreenState();
}

class _VerificationRequestDocsScreenState
    extends ConsumerState<VerificationRequestDocsScreen> {
  final Map<int, String?> _urls = {};

  @override
  void initState() {
    super.initState();
    for (final id in widget.request.proofMediaIds) {
      _loadUrl(id);
    }
  }

  Future<void> _loadUrl(int mediaId) async {
    final url =
        await ref.read(adminProvider.notifier).proofUrl(mediaId);
    if (!mounted) return;
    setState(() => _urls[mediaId] = url);
  }

  @override
  Widget build(BuildContext context) {
    return AdminWebLayout(
      title: 'Badge Request #${widget.request.id}',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRequester(),
            const SizedBox(height: 24),
            _buildNotes(),
            const SizedBox(height: 24),
            _buildDocuments(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequester() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Request'),
            const SizedBox(height: 16),
            _infoRow(LucideIcons.user, widget.request.requesterName),
            if (widget.request.requesterEmail.isNotEmpty)
              _infoRow(LucideIcons.mail, widget.request.requesterEmail),
            _infoRow(LucideIcons.shieldCheck,
                '${widget.request.verifiableType} #${widget.request.verifiableId}'),
            if (widget.request.createdAt != null)
              _infoRow(
                  LucideIcons.calendar, widget.request.createdAt!.split('T').first),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Notes'),
            const SizedBox(height: 12),
            if (widget.request.notes?.trim().isNotEmpty ?? false)
              Text(widget.request.notes!,
                  style: GoogleFonts.inter(
                      fontSize: 13, height: 1.5, color: AppColors.ink))
            else
              Text('No notes were provided.',
                  style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocuments() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Proof Documents'),
            const SizedBox(height: 16),
            if (widget.request.proofMediaIds.isEmpty)
              _empty('No documents were submitted with this request.')
            else
              ...widget.request.proofMediaIds.map(
                  (id) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _docPreview(id)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _docPreview(int mediaId) {
    final url = _urls[mediaId];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Media item #$mediaId',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: url == null
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.imageOff,
                            size: 44, color: AppColors.textTertiary),
                        const SizedBox(height: 8),
                        Text('Failed to load document',
                            style: GoogleFonts.inter(
                                color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _empty(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.triangleAlert, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child:
                Text(message, style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
