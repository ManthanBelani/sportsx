import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/theme/colors.dart';

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
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundImage: resolved != null ? NetworkImage(resolved) : null,
      onBackgroundImageError: resolved != null ? (error, stackTrace) {} : null,
      child: resolved == null ? Icon(LucideIcons.user, color: AppColors.primary, size: radius) : null,
    );
  }
}
