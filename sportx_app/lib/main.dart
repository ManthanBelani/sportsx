import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sportx_app/core/router.dart';
import 'package:sportx_app/core/services/push_notification_service.dart';
import 'package:sportx_app/firebase_options.dart';
import 'package:sportx_app/theme/app_theme.dart';

/// NOTE: Sentry crash reporting removed for now (it broke the Android
/// debug build: sentry_flutter's Kotlin language version vs AGP 8.11).
/// To re-enable: re-add `sentry_flutter` to pubspec.yaml and wrap [boot]
/// in `SentryFlutter.init` with `--dart-define=SENTRY_DSN=...`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Env asset missing — ApiConfig falls back to its built-in defaults.
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {
    // Firebase not configured — push notifications will be unavailable.
  }

  runApp(const ProviderScope(child: SportXApp()));
}

class SportXApp extends ConsumerStatefulWidget {
  const SportXApp({super.key});

  @override
  ConsumerState<SportXApp> createState() => _SportXAppState();
}

class _SportXAppState extends ConsumerState<SportXApp> {
  @override
  void initState() {
    super.initState();
    // Init foreground push handling after first frame (needs ref + navigatorKey)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        PushNotificationService.init(ref);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'SportX India',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
