import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class MapPinItem {
  final String name;
  final String subtitle;
  final double left; // 0..1 relative position in the map area
  final double top;
  const MapPinItem({
    required this.name,
    required this.subtitle,
    required this.left,
    required this.top,
  });
}

/// D.16 Map View (P2) — nearby academies/venues.
///
/// Map tiles are rendered as a stylised placeholder (no map SDK wired yet);
/// the pin sheet and list are fully functional. Swap the placeholder for
/// `flutter_map`/`google_maps_flutter` at integration time.
class MapViewScreen extends StatefulWidget {
  final String title;
  final List<MapPinItem> pins;

  const MapViewScreen({
    super.key,
    this.title = 'Nearby',
    this.pins = const [],
  });

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final pins = widget.pins.isEmpty ? _sample : widget.pins;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SportXTopBar(title: widget.title, showBack: true),
      body: Column(
        children: [
          Expanded(child: _map(pins)),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.mapPin,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('${pins.length} places nearby',
                    style: GoogleFonts.inter(
                        fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              itemCount: pins.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final p = pins[i];
                final active = i == _selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: active
                              ? AppColors.yellowDeep
                              : AppColors.border,
                          width: active ? 1.5 : 1),
                      borderRadius:
                          BorderRadius.circular(16),
                      boxShadow: SportXShadows.e2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                        const SizedBox(height: 2),
                        Text(p.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textSecondary)),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(LucideIcons.star,
                                size: 13, color: AppColors.yellowDeep),
                            const SizedBox(width: 4),
                            Text('4.6',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _map(List<MapPinItem> pins) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFFEAF0EA),
          child: Stack(
            children: [
              // Stylised grid placeholder
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _GridPainter(),
              ),
              for (var i = 0; i < pins.length; i++)
                Positioned(
                  left: pins[i].left * (constraints.maxWidth - 36),
                  top: pins[i].top * (constraints.maxHeight - 46),
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    child: Icon(
                      LucideIcons.mapPin,
                      size: i == _selected ? 36 : 28,
                      color: i == _selected
                          ? AppColors.yellowDeep
                          : AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static const _sample = [
    MapPinItem(name: 'Elite Cricket Academy', subtitle: 'Ahmedabad · Cricket', left: 0.22, top: 0.28),
    MapPinItem(name: 'Pro Football Ground', subtitle: 'Gandhinagar · Football', left: 0.58, top: 0.5),
    MapPinItem(name: 'Champions Sports Club', subtitle: 'Surat · Multi-sport', left: 0.4, top: 0.16),
  ];
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14000000)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
