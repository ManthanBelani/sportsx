import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
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
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? NetworkImage(photoUrl!)
          : null,
      onBackgroundImageError: photoUrl != null && photoUrl!.isNotEmpty
          ? (error, stackTrace) {}
          : null,
      child: photoUrl == null || photoUrl!.isEmpty
          ? Icon(LucideIcons.user, color: AppColors.primary, size: radius)
          : null,
    );
  }
}
