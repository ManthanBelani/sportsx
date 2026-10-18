import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_sheets.dart';

/// S.28 Media Viewer — full-screen photo/video with swipe, share, report.
class MediaViewerScreen extends StatefulWidget {
  final List<String> media;
  final int initialIndex;
  final String? title;

  const MediaViewerScreen({
    super.key,
    required this.media,
    this.initialIndex = 0,
    this.title,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(
        0, widget.media.isEmpty ? 0 : widget.media.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (widget.media.isEmpty)
            const Center(
              child: Icon(LucideIcons.imageOff, color: Colors.white54, size: 44),
            )
          else
            PageView.builder(
              controller: _controller,
              itemCount: widget.media.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => InteractiveViewer(
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.media[i],
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      LucideIcons.image,
                      color: Colors.white38,
                      size: 56,
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(LucideIcons.arrowLeft,
                          color: Colors.white),
                    ),
                    const Spacer(),
                    if (widget.media.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text('${_index + 1} / ${widget.media.length}',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.white70)),
                      ),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _action(
                        icon: LucideIcons.share2,
                        label: 'Share',
                        onTap: () => showShareSheet(context,
                            title: 'Share',
                            subtitle: widget.title ?? 'SportX media'),
                      ),
                      const SizedBox(width: 32),
                      _action(
                        icon: LucideIcons.flag,
                        label: 'Report',
                        onTap: () =>
                            showReportSheet(context, targetTitle: widget.title ?? ''),
                      ),
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

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
