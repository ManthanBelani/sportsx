import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/theme/colors.dart';

/// v2 avatar — yellow gradient ring (matches EntityRow/GreetCard avatars).
class AthleteAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;

  const AthleteAvatar({
    super.key,
    this.photoUrl,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = MediaUtils.resolveNullable(photoUrl);
    return Container(
      width: radius * 2,
      height: radius * 2,
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
        radius: radius - 2,
        backgroundColor: AppColors.yellowTint,
        backgroundImage: resolved != null ? NetworkImage(resolved) : null,
        onBackgroundImageError: resolved != null ? (error, stackTrace) {} : null,
        child: resolved == null ? Icon(LucideIcons.user, color: AppColors.ink, size: radius) : null,
      ),
    );
  }
}
