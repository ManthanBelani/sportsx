import 'package:flutter/material.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/theme/colors.dart';

/// v2 avatar — yellow gradient ring (matches EntityRow/GreetCard avatars).
/// Falls back to initials (then a user glyph) when the photo URL is null
/// or the network image fails to load (e.g. missing file on the server).
class AthleteAvatar extends StatefulWidget {
  final String? photoUrl;
  final double radius;

  /// Athlete's full name — used for the initials fallback.
  final String? name;

  const AthleteAvatar({
    super.key,
    this.photoUrl,
    this.radius = 24,
    this.name,
  });

  @override
  State<AthleteAvatar> createState() => _AthleteAvatarState();
}

class _AthleteAvatarState extends State<AthleteAvatar> {
  bool _failed = false;

  @override
  void didUpdateWidget(covariant AthleteAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) _failed = false;
  }

  String? get _initials {
    final name = widget.name?.trim();
    if (name == null || name.isEmpty) return null;
    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return parts.isEmpty ? null : parts;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = MediaUtils.resolveNullable(widget.photoUrl);
    final resolvedUrl = resolved;
    final showImage = resolvedUrl != null && !_failed;
    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE9A8), Color(0xFFFFC107), Color(0xFFF5B400)],
        ),
      ),
      alignment: Alignment.center,
      child: CircleAvatar(
        radius: widget.radius - 2,
        backgroundColor: AppColors.yellowTint,
        backgroundImage: showImage ? NetworkImage(resolvedUrl) : null,
        onBackgroundImageError: showImage
            ? (error, stackTrace) {
                if (mounted) setState(() => _failed = true);
              }
            : null,
        child: showImage
            ? null
            : _initials != null
                ? Text(
                    _initials!,
                    style: TextStyle(
                      fontSize: widget.radius * 0.55,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  )
                : Icon(Icons.person, color: AppColors.ink, size: widget.radius),
      ),
    );
  }
}
