import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const String _defaultBaseUrl = 'https://sportx.in/api/v1';

  /// Base URL of the SportX backend API (read from .env at runtime).
  /// Falls back to the default if .env is missing or the key is absent.
  static String get baseUrl => _get('API_BASE_URL', _defaultBaseUrl);

  /// Public web app URL, used for share links / deep links.
  static String get webBaseUrl => _get('WEB_BASE_URL', 'https://sportx.in');

  static Duration get connectTimeout =>
      Duration(seconds: _intFromEnv('API_CONNECT_TIMEOUT_SECONDS', 30));

  static Duration get receiveTimeout =>
      Duration(seconds: _intFromEnv('API_RECEIVE_TIMEOUT_SECONDS', 30));

  static const int maxRetries = 1;

  /// Reads a value from the loaded .env. When dotenv was never initialised
  /// (unit tests, or a host that does not ship a .env) the fallback is used
  /// instead of throwing.
  static String _get(String key, String fallback) {
    try {
      return dotenv.get(key, fallback: fallback);
    } catch (_) {
      return fallback;
    }
  }

  static int _intFromEnv(String key, int fallback) {
    final value = _maybeGet(key);
    return value == null ? fallback : (int.tryParse(value) ?? fallback);
  }

  static String? _maybeGet(String key) {
    try {
      return dotenv.maybeGet(key);
    } catch (_) {
      return null;
    }
  }
}
