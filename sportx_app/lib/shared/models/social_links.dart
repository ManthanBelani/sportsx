import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

/// Supported social platforms (keys match backend `users.social_links`).
class SocialPlatform {
  final String key;
  final String label;
  final IconData icon;
  final String hint;

  const SocialPlatform({required this.key, required this.label, required this.icon, required this.hint});
}

const List<SocialPlatform> kSocialPlatforms = [
  SocialPlatform(key: 'instagram', label: 'Instagram', icon: LucideIcons.camera, hint: 'instagram.com/yourname'),
  SocialPlatform(key: 'facebook', label: 'Facebook', icon: LucideIcons.thumbsUp, hint: 'facebook.com/yourname'),
  SocialPlatform(key: 'youtube', label: 'YouTube', icon: LucideIcons.play, hint: 'youtube.com/@yourchannel'),
  SocialPlatform(key: 'x', label: 'X (Twitter)', icon: LucideIcons.atSign, hint: 'x.com/yourname'),
  SocialPlatform(key: 'linkedin', label: 'LinkedIn', icon: LucideIcons.briefcaseBusiness, hint: 'linkedin.com/in/yourname'),
  SocialPlatform(key: 'website', label: 'Website', icon: LucideIcons.globe, hint: 'yourwebsite.com'),
];

/// Extract a {platform: url} map from any profile payload.
/// Reads profile['user']['social_links'] first, then profile['social_links'].
Map<String, String> socialLinksOf(Map<String, dynamic>? profile) {
  final out = <String, String>{};
  if (profile == null) return out;
  dynamic raw = (profile['user'] is Map) ? (profile['user'] as Map)['social_links'] : null;
  raw ??= profile['social_links'];
  if (raw is Map) {
    for (final p in kSocialPlatforms) {
      final v = raw[p.key]?.toString().trim() ?? '';
      if (v.isNotEmpty) out[p.key] = v;
    }
  }
  return out;
}
