import 'package:intl/intl.dart';

class DateFormatUtils {
  /// Formats date and time as 'DD-MM-YYYY • h:mm a' (e.g. 15-08-2024 • 2:30 PM)
  static String formatDisplayDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final time = DateFormat('h:mm a').format(dt);
    return '$d-$m-$y • $time';
  }

  /// Formats date only as 'DD-MM-YYYY' (e.g. 15-08-2024)
  static String formatShortDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    return formatDdMmYyyy(dt);
  }

  /// Formats relative time for recent items or 'DD-MM-YYYY' for older items
  static String formatRelative(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final now = DateTime.now();
    final local = dt.isUtc ? dt.toLocal() : dt;
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDdMmYyyy(local);
  }

  /// Formats chat timestamps:
  /// today -> 'h:mm a'
  /// older -> 'DD-MM-YYYY • h:mm a'
  static String formatChatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    final now = DateTime.now();
    final timeStr = DateFormat('h:mm a').format(dt);
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) return timeStr;
    return '${formatDdMmYyyy(dt)} • $timeStr';
  }

  static String formatTimeOnly(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    return DateFormat('h:mm a').format(dt);
  }

  /// Formats any date (DateTime, String in ISO, etc.) as 'DD-MM-YYYY' (e.g. 15-10-2004)
  static String formatDdMmYyyy(dynamic date) {
    if (date == null) return '';
    DateTime? dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      final s = date.trim();
      if (s.isEmpty) return '';
      // If already DD-MM-YYYY, return directly
      if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(s)) return s;
      dt = DateTime.tryParse(s);
    }
    if (dt == null) return date.toString();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d-$m-$y';
  }

  /// Formats date and time as 'DD-MM-YYYY • h:mm a'
  static String formatDdMmYyyyTime(dynamic date) {
    if (date == null) return '';
    DateTime? dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      final s = date.trim();
      if (s.isEmpty) return '';
      dt = DateTime.tryParse(s);
    }
    if (dt == null) return date.toString();
    final local = dt.isUtc ? dt.toLocal() : dt;
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString();
    final time = DateFormat('h:mm a').format(local);
    return '$d-$m-$y • $time';
  }

  /// Backend ISO representation: YYYY-MM-DD
  static String formatIsoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
