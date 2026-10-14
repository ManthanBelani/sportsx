import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

/// Phase 9 prefs (v3): global push + per-category toggles.
class NotificationPrefs {
  final bool push;
  final Map<String, bool> categories;
  final List<String> hardOverrides;

  NotificationPrefs({required this.push, required this.categories, required this.hardOverrides});

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) {
    final prefs = json['prefs'] as Map<String, dynamic>? ?? {};
    final cats = (prefs['categories'] as Map?)?.map((k, v) => MapEntry(k.toString(), v == true)) ?? {};
    return NotificationPrefs(
      push: prefs['push'] != false,
      categories: Map<String, bool>.from(cats),
      hardOverrides: ((json['hard_overrides'] as List?) ?? []).map((e) => e.toString()).toList(),
    );
  }
}

final notificationPrefsProvider = FutureProvider<NotificationPrefs>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/notification-preferences');
  return NotificationPrefs.fromJson(resp.data['data'] as Map<String, dynamic>);
});

Future<bool> updateNotificationPrefs(
  WidgetRef ref, {
  bool? push,
  Map<String, bool>? categories,
}) async {
  try {
    await ref.read(dioProvider).put('/me/notification-preferences', data: {
      if (push != null) 'push': push,
      if (categories != null) 'categories': categories,
    });
    ref.invalidate(notificationPrefsProvider);
    return true;
  } on DioException {
    return false;
  }
}

Future<bool> logAnalyticsEvent(WidgetRef ref, String event, [Map<String, dynamic>? props]) async {
  try {
    await ref.read(dioProvider).post('/analytics/events', data: {
      'event': event,
      if (props != null) 'props': props,
    });
    return true;
  } on DioException {
    return false;
  }
}
