import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

/// v2 create-sheet.html — FAB "Create" bottom sheet.
/// Pure navigation menu. Logic: pop sheet, then push the existing route.
class _CreateAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tintBg;
  final Color tintFg;
  final String route;
  const _CreateAction(this.title, this.subtitle, this.icon, this.tintBg,
      this.tintFg, this.route);
}

const _actions = [
  _CreateAction('Create Post', 'Share an update with your network',
      LucideIcons.penLine, Color(0xFFE3EFFF), AppColors.info, '/create-post'),
  _CreateAction('Create Opportunity', 'Trials, tournaments & more',
      LucideIcons.plusCircle, AppColors.yellowTint, AppColors.warnText, '/post-trial'),
  _CreateAction('Add Achievement', 'Medals, records & certificates',
      LucideIcons.award, Color(0xFFDCFCE7), Color(0xFF15803D), '/add-achievement'),
  _CreateAction('Add Event', 'Host a match or meetup', LucideIcons.calendarPlus,
      Color(0xFFECE9FF), AppColors.coach, '/post-tournament'),
  _CreateAction('Upload Photo/Video', 'Showcase your highlights',
      LucideIcons.imagePlus, Color(0xFFFEE2E2), AppColors.error, '/media-gallery'),
];

/// Shows the v2 create sheet. Call from the bottom-nav FAB.
Future<void> showCreateSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: false,
    builder: (_) => const _CreateSheet(),
  );
}

class _CreateSheet extends StatelessWidget {
  const _CreateSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99)),
            ),
          ),
          const SizedBox(height: 12),
          Text('Create',
              style: GoogleFonts.sora(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 2),
          Text('What would you like to do?',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final a in _actions) _row(context, a),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, _CreateAction a) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.push(a.route);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: a.tintBg,
                  borderRadius: BorderRadius.circular(15)),
              alignment: Alignment.center,
              child: Icon(a.icon, size: 22, color: a.tintFg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title,
                      style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(a.subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                color: Color(0xFFC9CDD3), size: 20),
          ],
        ),
      ),
    );
  }
}
