import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/media_utils.dart';

class AchievementEntry {
  final dynamic id;
  final String title;
  final String year;
  final String description;
  final String? certificateUrl;

  const AchievementEntry({
    required this.id,
    required this.title,
    required this.year,
    this.description = '',
    this.certificateUrl,
  });

  factory AchievementEntry.fromMap(Map item) {
    final m = Map<String, dynamic>.from(item);
    // Server variants: title/text for the label; certificate_media nested
    // object vs flat url depending on the serialiser.
    final certificate = m['certificate_media'] as Map?;
    final certUrl = (certificate?['url'] ??
            certificate?['file_url'] ??
            m['certificate_url'] ??
            m['certificateUrl'])
        as String?;
    return AchievementEntry(
      id: m['id'],
      title: (m['title'] ?? m['text'] ?? 'Achievement').toString(),
      year: (m['year'] ?? m['date'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      certificateUrl: certUrl == null || certUrl.isEmpty ? null : MediaUtils.resolveUrl(certUrl),
    );
  }
}

/// AT.5 Achievements — typed Phase-2 CRUD over /me/achievements.
/// Read via [FutureProvider]; mutations invalidate (no in-memory expiry).
final achievementsProvider = FutureProvider<List<AchievementEntry>>((ref) async {
  try {
    final resp = await ref.read(dioProvider).get('/me/achievements');
    final list = resp.data['data'] as List? ?? const [];
    return list
        .whereType<Map>()
        .map((e) => AchievementEntry.fromMap(e))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
});
