import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const String _defaultBaseUrl = 'http://127.0.0.1:8002/api/v1';

  /// Base URL of the SportX backend API (read from .env at runtime).
  /// Falls back to the default if .env is missing or the key is absent.
  static String get baseUrl =>
      dotenv.get('API_BASE_URL', fallback: _defaultBaseUrl);

  /// Public web app URL, used for share links / deep links.
  static String get webBaseUrl =>
      dotenv.get('WEB_BASE_URL', fallback: 'https://sportx.in');

  static Duration get connectTimeout =>
      Duration(seconds: _intFromEnv('API_CONNECT_TIMEOUT_SECONDS', 30));

  static Duration get receiveTimeout =>
      Duration(seconds: _intFromEnv('API_RECEIVE_TIMEOUT_SECONDS', 30));

  static const int maxRetries = 1;

  static int _intFromEnv(String key, int fallback) {
    final value = dotenv.maybeGet(key);
    return value == null ? fallback : (int.tryParse(value) ?? fallback);
  }
}
