import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/notifications/presentation/providers/notifications_provider.dart';

/// Handles FCM foreground/background display and token sync.
/// Call `PushNotificationService.init(ref)` once after Firebase.initializeApp.
class PushNotificationService {
  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  static Future<void> init(WidgetRef ref) async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS / Android 13+)
    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (_) {}

    // Refresh in-app bell when a push arrives in foreground
    _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
      // Refresh inbox
      try {
        await ref.read(notificationsProvider.notifier).load();
      } catch (_) {}
      // Show a simple in-app banner via SnackBar if we have context
      final title = msg.notification?.title ?? msg.data['title'] ?? 'SportX';
      final body = msg.notification?.body ?? msg.data['body'] ?? '';
      _showForegroundSnackBar(title, body);
    });

    // When user taps a notification
    _onMessageOpenedSub?.cancel();
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      try {
        ref.read(notificationsProvider.notifier).load();
      } catch (_) {}
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
