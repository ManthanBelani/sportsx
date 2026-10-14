import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/notifications/presentation/providers/notifications_provider.dart';

/// Handles FCM foreground/background display and token sync.
/// Call `PushNotificationService.init(ref)` once after Firebase.initializeApp.
///
/// Android channel ids MUST match backend FCMService mapping:
/// sportx_default | sportx_enquiries | sportx_reminders | sportx_updates | sportx_announcements
class PushNotificationService {
  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static bool _channelsReady = false;

  static const _channelIds = [
    'sportx_default',
    'sportx_enquiries',
    'sportx_reminders',
    'sportx_updates',
    'sportx_announcements',
  ];

  static Future<void> _ensureChannels() async {
    if (_channelsReady) return;
    try {
      const init = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _local.initialize(init, onDidReceiveNotificationResponse: (resp) {
        final action = resp.payload;
        if (action != null && action.isNotEmpty && navigatorKey.currentContext != null) {
          try {
            navigatorKey.currentContext!.go(action);
          } catch (_) {}
        }
      });
      final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        for (final id in _channelIds) {
          await android.createNotificationChannel(AndroidNotificationChannel(id, id.replaceAll('sportx_', 'SportX '), importance: Importance.high));
        }
      }
      _channelsReady = true;
    } catch (_) {}
  }

  static String _channelFor(RemoteMessage msg) {
    final c = (msg.data['channel_id'] ?? msg.data['channel'] ?? msg.data['category'] ?? '').toString();
    if (_channelIds.contains(c)) return c;
    // Backend maps per type; fall back to default rather than dropping (Android 8+).
    return 'sportx_default';
  }

  static void _deepLink(RemoteMessage msg) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final action = (msg.data['action_url'] ?? msg.data['actionUrl'] ?? '').toString();
    if (action.isEmpty) return;
    try {
      // Server re-authorizes on the target screen load; client just navigates.
      ctx.go(action);
    } catch (_) {}
  }

  static Future<void> _showLocal(RemoteMessage msg) async {
    final title = msg.notification?.title ?? msg.data['title']?.toString() ?? 'SportX';
    final body = msg.notification?.body ?? msg.data['body']?.toString() ?? '';
    final action = (msg.data['action_url'] ?? '').toString();
    try {
      await _local.show(
        msg.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(_channelFor(msg), 'SportX', importance: Importance.high, priority: Priority.high),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        payload: action.isNotEmpty ? action : null,
      );
    } catch (_) {
      _showForegroundSnackBar(title, body);
    }
  }

  static Future<void> init(WidgetRef ref) async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS foreground display + Android 13+ runtime prompt).
    // Requires POST_NOTIFICATIONS in AndroidManifest (added) — without it this is a silent no-op.
    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true, provisional: false);
      await messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    } catch (_) {}

    await _ensureChannels();

    // Cold-start tap (killed app) → deep link via action_url + category.
    try {
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        try {
          await ref.read(notificationsProvider.notifier).load();
        } catch (_) {}
        _deepLink(initial);
      }
    } catch (_) {}

    // Refresh in-app bell when a push arrives in foreground + show visible banner.
    _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
      try {
        await ref.read(notificationsProvider.notifier).load();
      } catch (_) {}
      await _showLocal(msg);
    });

    // Background/banners taps → reload + deep link.
    _onMessageOpenedSub?.cancel();
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      try {
        ref.read(notificationsProvider.notifier).load();
      } catch (_) {}
      _deepLink(msg);
    });

    // Keep server token fresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        final dio = ref.read(dioProvider);
        final deviceType = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
        await dio.post('/me/device-tokens', data: {'token': newToken, 'device_type': deviceType});
      } catch (_) {}
    });
  }

  static void _showForegroundSnackBar(String title, String body) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
            if (body.isNotEmpty) Text(body, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF111111),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Background handler must be top-level — see function below.
}

/// Global navigator key to show SnackBars from service
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate — inbox will refresh on next foreground open.
}
