import 'package:sportx_app/core/config/api_config.dart';

class MediaUtils {
  /// Resolves a backend `url` (which may be relative like `/storage/...`
  /// or absolute like `https://...`) into an absolute URL suitable for
  /// `NetworkImage` / `Image.network`. Uses `ApiConfig.baseUrl` to derive
  /// the origin when a relative path is given, so the media remains visible
  /// after app restart regardless of which role uploaded it.
  static String resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '').replaceFirst(RegExp(r'/$'), '');
    if (url.startsWith('/')) return '$base$url';
    return '$base/$url';
  }

  /// Returns null for empty/invalid URLs, otherwise the resolved absolute URL.
  static String? resolveNullable(String? url) {
    final resolved = resolveUrl(url);
    return resolved.isEmpty ? null : resolved;
  }
}
