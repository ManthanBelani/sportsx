import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/home_kit.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Design kit for the organizer board (design board screens 1–11).
///
/// Every widget here is a direct port of one of the board's components so the
/// organizer role renders the same shape, spacing and colour as the shipped
/// design: date blocks, "Registrations Open" pills, stat tiles, quick-action
/// tiles, the analytics KPI grid, the line chart and the "Top Sources" bars.

const _months = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// Indian digit grouping — 1,60,000 (lakh) / 1,20,00,000 (crore).
String formatIndianNumber(num value) {
  final negative = value < 0;
  var digits = value.abs().toStringAsFixed(0);
  var out = '';
  if (digits.length > 3) {
    out = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    while (rest.length > 2) {
      out = '${rest.substring(rest.length - 2)},$out';
      rest = rest.substring(0, rest.length - 2);
    }
    out = '$rest,$out';
  } else {
    out = digits;
  }
  return negative ? '-$out' : out;
}

/// Short Indian-formatted value for the stat tiles — 12K+ / 2.4L.
String compactIndianNumber(num value) {
  final v = value.abs();
  if (v >= 100000) {
    final l = v / 100000;
    return '${l.toStringAsFixed(l.truncateToDouble() == l ? 0 : 1)}L';
  }
  if (v >= 1000) {
    final k = v / 1000;
    return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
  }
  return '${v.round()}';
}

/// Design board · date block — "NOV / 20-22 / 2026".
class OrgDateBlock extends StatelessWidget {
  final DateTime? start;
  final DateTime? end;
  final double width;

  const OrgDateBlock({super.key, this.start, this.end, this.width = 54});

  @override
  Widget build(BuildContext context) {
    final s = start;
    final dayLabel = s == null
        ? 'TBA'
        : (end != null && end!.day != s.day
              ? '${s.day}-${end!.day}'
              : '${s.day}');
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: SportXShadows.e1,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s == null ? '—' : _months[s.month - 1],
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.organizer,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            dayLabel,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (s != null) ...[
            const SizedBox(height: 1),
            Text(
              '${s.year}',
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum OrgPillKind { open, pending, draft, closed, info, danger }

/// Design board · pill — "Registrations Open" (green, with dot).
class OrgPill extends StatelessWidget {
  final String label;
  final OrgPillKind kind;
  final bool dot;

  const OrgPill(
    this.label, {
    super.key,
    this.kind = OrgPillKind.info,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (kind) {
      OrgPillKind.open => (
        AppColors.successLight,
        const Color(0xFF15803D),
        const Color(0x4D22C55E),
      ),
      OrgPillKind.pending => (
        AppColors.yellowTint,
        AppColors.warnText,
        const Color(0x4DF59E0B),
      ),
      OrgPillKind.draft => (
        AppColors.surface,
        AppColors.textSecondary,
        AppColors.border,
      ),
      OrgPillKind.closed => (
        AppColors.errorLight,
        const Color(0xFFB91C1C),
        const Color(0x40EF4444),
      ),
      OrgPillKind.danger => (
        AppColors.errorLight,
        const Color(0xFFB91C1C),
        const Color(0x40EF4444),
      ),
      OrgPillKind.info => (
        AppColors.infoLight,
        AppColors.info,
        const Color(0x3D3B82F6),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Design board · event card — thumbnail, date block, title, location,
/// "Registrations Open" pill and the registered count (with an optional
/// trailing menu and a "View" CTA, both used by the My Events / Explore
/// screens of the board).
class OrgEventCard extends StatelessWidget {
  final String title;
  final DateTime? start;
  final DateTime? end;
  final String location;
  final String? sportName;
  final String? bannerUrl;
  final bool registrationsOpen;
  final int registeredCount;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onView;

  const OrgEventCard({
    super.key,
    required this.title,
    required this.start,
    this.end,
    required this.location,
    this.sportName,
    this.bannerUrl,
    this.registrationsOpen = true,
    this.registeredCount = 0,
    this.trailing,
    this.onTap,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(bannerUrl: bannerUrl, sportName: sportName),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 4),
                        trailing!,
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 11,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (sportName != null && sportName!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      sportName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      if (registrationsOpen)
                        const OrgPill(
                          'Registrations Open',
                          kind: OrgPillKind.open,
                          dot: true,
                        ),
                      const Spacer(),
                      if (onView != null)
                        CompactPrimaryButton(label: 'View', onTap: onView)
                      else
                        Text(
                          '$registeredCount Registered',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDarker,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OrgDateBlock(start: start, end: end),
          ],
        ),
      ),
    );
  }
}

/// Event thumbnail — real banner when the backend returned one, otherwise a
/// tinted placeholder block with the event's sport icon.
class _Thumb extends StatelessWidget {
  final String? bannerUrl;
  final String? sportName;
  const _Thumb({this.bannerUrl, this.sportName});

  @override
  Widget build(BuildContext context) {
    final url = bannerUrl;
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        color: AppColors.infoLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: (url != null && url.isNotEmpty)
          ? Image.network(
              MediaUtils.resolveUrl(url),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ThumbFallback(),
            )
          : const _ThumbFallback(),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3EFFF), Color(0xFFFFF8E7)],
        ),
      ),
      child: const Center(
        child: Icon(
          LucideIcons.trophy,
          size: 26,
          color: AppColors.primaryDarker,
        ),
      ),
    );
  }
}

/// Design board · quick action tile — icon square + centred label.
class OrgQuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconFg;
  final VoidCallback? onTap;

  const OrgQuickTile({
    super.key,
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconFg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: SportXShadows.e1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 15, color: iconFg),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Design board · stat tile (home) — big value over a soft label.
class OrgStatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;

  const OrgStatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AppColors.primaryDarker),
            const SizedBox(height: 4),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Design board · analytics KPI tile — label, value and a delta chip.
class OrgKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final double? delta;
  final IconData? icon;

  const OrgKpiTile({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final up = (delta ?? 0) >= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: SportXShadows.e1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (icon != null)
                Icon(icon, size: 13, color: AppColors.primaryDarker),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          if (delta != null) ...[
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  up ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                  size: 12,
                  color: up ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 3),
                Text(
                  '${delta!.abs().round()}%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: up ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Design board · "Top Sources" bar row.
class OrgBarRow extends StatelessWidget {
  final String label;
  final double percent;
  final IconData? icon;

  /// Raw count next to the percentage ("12,450 · 64%").
  final int? count;

  const OrgBarRow({
    super.key,
    required this.label,
    required this.percent,
    this.icon,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (count != null)
                Text(
                  '${formatIndianNumber(count!)}  ',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
              Text(
                '${percent.round()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0, 1),
              minHeight: 7,
              backgroundColor: AppColors.borderSoft,
              valueColor: const AlwaysStoppedAnimation(AppColors.yellow),
            ),
          ),
        ],
      ),
    );
  }
}

/// Design board · "Registrations" line chart.
class OrgLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> xLabels;

  const OrgLineChart({super.key, required this.values, required this.xLabels});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          width: double.infinity,
          child: CustomPaint(
            painter: _LinePainter(
              values: values,
              lineColor: AppColors.info,
              gridColor: AppColors.borderSoft,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in xLabels)
              Text(
                l,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color gridColor;

  _LinePainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Horizontal grid lines.
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.length < 2) return;

    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final span = (maxV - minV).abs() < 0.0001 ? 1.0 : maxV - minV;
    final dx = size.width / (values.length - 1);

    Offset pointAt(int i) {
      final x = dx * i;
      final y =
          size.height - ((values[i] - minV) / span) * (size.height - 16) - 8;
      return Offset(x, y);
    }

    // Smooth-ish path through the points.
    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 0; i < values.length - 1; i++) {
      final p0 = pointAt(i);
      final p1 = pointAt(i + 1);
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    // Area fill under the line.
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.22),
            lineColor.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // Dots.
    final dot = Paint()..color = lineColor;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(pointAt(i), 3.2, dot);
      canvas.drawCircle(pointAt(i), 1.6, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.lineColor != lineColor;
}
