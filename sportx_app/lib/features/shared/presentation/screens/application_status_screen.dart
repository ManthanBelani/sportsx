import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

/// v2 application-status.html — application tracker timeline.
/// Read-only view driven by route extra:
/// {kind, title, ref, status}. Status mapping:
/// pending → Under Review current; approved/shortlisted → step 3 current;
/// rejected/closed → terminal note; otherwise step 1 current.
class ApplicationStatusScreen extends StatelessWidget {
  final String kind;
  final String title;
  final String refCode;
  final String status;
  const ApplicationStatusScreen({
    super.key,
    this.kind = 'trial',
    this.title = 'Application',
    this.refCode = '',
    this.status = 'pending',
  });

  int get _currentStep {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'shortlisted':
      case 'accepted':
        return 2;
      case 'rejected':
      case 'closed':
        return 4;
      case 'pending':
        return 1;
      default:
        return 0;
    }
  }

  bool get _isTerminal =>
      status.toLowerCase() == 'rejected' || status.toLowerCase() == 'closed';

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Applied', 'Application received'),
      ('Under Review', 'Organizer is reviewing your profile'),
      ('Shortlisted', 'Await shortlist announcement'),
      ('Final Selection', 'On-ground ${kind == 'trial' ? 'trial' : 'tournament'} round'),
      ('Result', 'Published after finals'),
    ];
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
        title: Text('Application Status',
            style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(18),
              boxShadow: SportXShadows.e1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.sora(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(
                    '${kind[0].toUpperCase()}${kind.substring(1)}${refCode.isNotEmpty ? ' · Ref $refCode' : ''}',
                    style: GoogleFonts.inter(
                        fontSize: 12.5, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                StatusPill(
                    label: _isTerminal
                        ? 'Closed'
                        : status.toLowerCase() == 'approved' ||
                                status.toLowerCase() == 'shortlisted'
                            ? 'Shortlisted'
                            : 'Under Review',
                    kind: _isTerminal ? PillKind.no : PillKind.pending),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(18),
              boxShadow: SportXShadows.e1,
            ),
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++)
                  _step(
                    index: i,
                    title: steps[i].$1,
                    subtitle: steps[i].$2,
                    isLast: i == steps.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.yellowTint,
              border: Border.all(color: const Color(0xFFF0E3B2)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.bellRing,
                    size: 18, color: AppColors.warnText),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      "We'll notify you once there's an update.",
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.dark, height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(
      {required int index,
      required String title,
      required String subtitle,
      required bool isLast}) {
    final cur = _currentStep;
    final done = index < cur || (_isTerminal && index == 0);
    final current = index == cur && !_isTerminal;
    final dotBg = done
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2BD56B), Color(0xFF16A34A)])
        : current
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFD54A), Color(0xFFF5B400)])
            : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: dotBg,
                color: dotBg == null ? Colors.white : null,
                border: dotBg == null
                    ? Border.all(color: AppColors.border, width: 2)
                    : null,
                boxShadow: SportXShadows.e1,
              ),
              alignment: Alignment.center,
              child: Icon(
                  done
                      ? LucideIcons.check
                      : current
                          ? LucideIcons.loader
                          : LucideIcons.circle,
                  size: 15,
                  color: done
                      ? Colors.white
                      : current
                          ? AppColors.ink
                          : AppColors.textTertiary),
            ),
            if (!isLast)
              Container(width: 2, height: 26, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 12 : 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
