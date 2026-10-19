import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
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
  static bool _tokenRegistered = false;

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

  /// Normalize action URL from various possible keys in the push payload
  static String? _parseActionUrl(RemoteMessage msg) {
    return (msg.data['action_url'] ??
            msg.data['actionUrl'] ??
            msg.data['deep_link'] ??
            msg.data['deeplink'])?.toString();
  }

  static void _deepLink(RemoteMessage msg) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final action = _parseActionUrl(msg);
    if (action == null || action.isEmpty) return;
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

  /// Only fire user-scoped refreshes when a session actually exists —
  /// previously these ran unconditionally and produced 401 spam.
  static bool _isAuthed(dynamic ref) {
    try {
      return ref.read(authProvider).status == AuthStatus.authenticated;
    } catch (_) {
      return false;
    }
  }

  static void _refreshBell(dynamic ref) {
    if (!_isAuthed(ref)) return;
    try {
      ref.read(notificationsProvider.notifier).load();
    } catch (_) {}
  }

  static Future<void> init(dynamic ref) async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS foreground display + Android 13+ runtime prompt).
    // Requires POST_NOTIFICATIONS in AndroidManifest (added) — without it this is a silent no-op.
    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true, provisional: false);
      await messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    } catch (_) {}

    await _ensureChannels();

    // Register FCM token if authenticated (guarded to prevent duplicates)
    await _registerTokenIfNeeded(ref);

    // Cold-start tap (killed app) → deep link via action_url + category.
    try {
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _refreshBell(ref);
        _deepLink(initial);
      }
    } catch (_) {}

    // Refresh in-app bell when a push arrives in foreground + show visible banner.
    _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
      _refreshBell(ref);
      await _showLocal(msg);
    });

    // Background/banners taps → reload + deep link.
    _onMessageOpenedSub?.cancel();
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      _refreshBell(ref);
      _deepLink(msg);
    });

    // Keep server token fresh (authenticated sessions only)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (!_isAuthed(ref)) return;
      try {
        final dio = ref.read(dioProvider);
        final deviceType = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
        await dio.post('/me/device-tokens', data: {'token': newToken, 'device_type': deviceType});
      } catch (_) {}
    });
  }

  /// Register FCM token with guard to prevent duplicate registrations
  static Future<void> _registerTokenIfNeeded(dynamic ref) async {
    if (_tokenRegistered) return;
    if (!_isAuthed(ref)) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final dio = ref.read(dioProvider);
        final deviceType = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
        await dio.post('/me/device-tokens', data: {'token': token, 'device_type': deviceType});
        _tokenRegistered = true;
      }
    } catch (_) {}
  }

  /// Call this when auth state changes to authenticated
  static Future<void> registerTokenOnAuth(dynamic ref) async {
    _tokenRegistered = false; // Reset guard for new session
    await _registerTokenIfNeeded(ref);
  }

  /// Call this when auth state changes to unauthenticated
  static void clearTokenRegistration() {
    _tokenRegistered = false;
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

  /// Process any pending notifications from background handler
  /// Call this after app initialization when user is authenticated
  static Future<void> processPendingNotifications(dynamic ref) async {
    if (!_isAuthed(ref)) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('pending_notifications') ?? [];
      if (pending.isEmpty) return;
      
      // Clear pending list
      await prefs.remove('pending_notifications');
      
      // Process each notification
      for (final item in pending) {
        try {
          final data = jsonDecode(item) as Map<String, dynamic>;
          final msgData = data['data'] as Map<String, dynamic>?;
          if (msgData != null) {
            // Refresh in-app bell
            _refreshBell(ref);
            // Handle deep link if present
            final action = (msgData['action_url'] ?? 
                           msgData['actionUrl'] ?? 
                           msgData['deep_link'] ?? 
                           msgData['deeplink'])?.toString();
            if (action != null && action.isNotEmpty && navigatorKey.currentContext != null) {
              navigatorKey.currentContext!.go(action);
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  // Background handler must be top-level — see function below.
}

/// Global navigator key to show SnackBars from service
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Background handler - stores notification for processing on next app open
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Initialize Firebase if needed (in background isolate)
    await Firebase.initializeApp();
    
    // Store notification data for processing when app opens
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('pending_notifications') ?? [];
    final notificationData = {
      'data': message.data,
      'notification': message.notification?.toMap(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    pending.add(jsonEncode(notificationData));
    // Keep only last 50 notifications
    if (pending.length > 50) {
      pending.removeRange(0, pending.length - 50);
    }
    await prefs.setStringList('pending_notifications', pending);
  } catch (_) {
    // Silently fail in background
  }
}
