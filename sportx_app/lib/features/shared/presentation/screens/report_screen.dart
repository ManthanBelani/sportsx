import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// v2 report-listing.html — standalone Report screen.
/// Same POST /reports contract as the detail-page report dialog:
/// {reportable_type, reportable_id, reason, comment}.
class ReportScreen extends ConsumerStatefulWidget {
  final String type;
  final String itemId;
  final String title;
  const ReportScreen(
      {super.key, this.type = '', this.itemId = '', this.title = ''});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  static const _reasons = {
    'spam': 'Spam',
    'inappropriate': 'Inappropriate content',
    'fake': 'Fake listing',
    'harassment': 'Harassment',
    'other': 'Other',
  };
  String _reason = 'spam';
  final _comment = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.type.isEmpty || widget.itemId.isEmpty) {
      SnackBarUtils.showError(context, 'This item cannot be reported');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(dioProvider).post('/reports', data: {
        'reportable_type': widget.type,
        'reportable_id': int.parse(widget.itemId),
        'reason': _reason,
        'comment': _comment.text.trim(),
      });
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Report submitted. Thank you!');
      context.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, ApiException.fromDio(e).message);
      setState(() => _submitting = false);
    } catch (_) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Could not submit report');
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.ink),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text('Report Content',
            style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          if (widget.title.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
                boxShadow: SportXShadows.e1,
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.flag,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 13.5, color: AppColors.dark)),
                  ),
                ],
              ),
            ),
          Text('WHY ARE YOU REPORTING THIS?',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.dark)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: SportXShadows.e1,
            ),
            child: Column(
              children: [
                for (final e in _reasons.entries)
                  GestureDetector(
                    onTap: _submitting
                        ? null
                        : () => setState(() => _reason = e.key),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: e.key == _reasons.keys.last
                                ? BorderSide.none
                                : const BorderSide(
                                    color: AppColors.borderSoft)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _reason == e.key
                                      ? AppColors.yellowDeep
                                      : AppColors.border,
                                  width: _reason == e.key ? 6 : 1.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(e.value,
                                style: GoogleFonts.inter(
                                    fontSize: 14, color: AppColors.ink)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('DETAILS (OPTIONAL)',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.dark)),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLines: 4,
            enabled: !_submitting,
            decoration: const InputDecoration(
                hintText: 'Add details that help our moderators…'),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: _submitting
                ? Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFD54A),
                            Color(0xFFFFC107),
                            Color(0xFFF5B400)
                          ]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.ink)),
                  )
                : PrimaryButton(
                    label: 'Submit Report', onPressed: _submit),
          ),
        ),
      ),
    );
  }
}
