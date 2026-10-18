import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class ConversationItem {
  final String id;
  final String title;
  final String? lastMessage;
  final String? lastMessageAt;

  ConversationItem({
    required this.id,
    required this.title,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    final messages = (json['messages'] as List? ?? []).cast<Map<String, dynamic>>();
    final last = messages.isNotEmpty ? messages.first : null;
    final participants = (json['participants'] as List? ?? []).cast<Map<String, dynamic>>();
    final title = (json['title'] as String?) ??
        participants.map((p) => (p['name'] ?? 'User').toString()).join(', ');
    return ConversationItem(
      id: json['id']?.toString() ?? '',
      title: title.isEmpty ? 'Conversation' : title,
      lastMessage: last?['body'] as String?,
      lastMessageAt: last?['created_at'] as String? ?? json['updated_at'] as String?,
    );
  }
}

class ChatMessage {
  final String id;
  final String body;
  final String senderId;
  final String senderName;
  final String? createdAt;

  ChatMessage({
    required this.id,
    required this.body,
    required this.senderId,
    required this.senderName,
    this.createdAt,
  });

  /// Sender ids arrive in mixed shapes ("7", 7, or "users/7") — normalize to
  /// the trailing numeric id so `senderId == currentUserId` actually matches
  /// and bubbles align to the right side for the current user.
  static String _normalizedId(dynamic raw) {
    final s = raw?.toString() ?? '';
    final m = RegExp(r'(\d+)\s*$').firstMatch(s);
    return m != null ? m.group(1)! : s;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      body: (json['body'] ?? '').toString(),
      senderId: _normalizedId(sender?['id'] ?? json['sender_user_id']),
      senderName: (sender?['name'] ?? 'User').toString(),
      createdAt: json['created_at'] as String?,
    );
  }
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Short human time for chat lists/bubbles:
/// today → 10:42 · yesterday → Yesterday · <7d → Tue · this year → 12 Oct · older → 12/10/25.
String shortChatTime(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  final local = dt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = today.difference(day).inDays;
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  if (diff == 0) return '$hh:$mm';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return _weekdays[local.weekday - 1];
  if (local.year == now.year) return '${local.day} ${_months[local.month - 1]}';
  return '${local.day}/${local.month}/${local.year % 100}';
}

final conversationsProvider = FutureProvider<List<ConversationItem>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/conversations');
  final data = resp.data['data'];
  return (data as List).map((e) => ConversationItem.fromJson(e as Map<String, dynamic>)).toList();
});

final conversationDetailProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, id) async {
  final resp = await ref.watch(dioProvider).get('/conversations/$id');
  final body = resp.data['data'] as Map<String, dynamic>;
  final messages = (body['messages'] as List? ?? []).cast<Map<String, dynamic>>();
  return messages.map(ChatMessage.fromJson).toList();
});

Future<bool> sendMessage(WidgetRef ref, String conversationId, String body) async {
  try {
    await ref.read(dioProvider).post('/conversations/$conversationId/messages', data: {'body': body});
    ref.invalidate(conversationDetailProvider(conversationId));
    ref.invalidate(conversationsProvider);
    return true;
  } on DioException {
    return false;
  }
}

Future<String?> startConversation(WidgetRef ref, int participantId) async {
  final result = await startConversationResult(ref, participantId);
  return result.$1;
}

/// Starts (or reuses) a 1:1 conversation, surfacing gate errors.
/// Returns (conversationId, errorMessage). errorMessage is e.g. 'Connect first…'
/// when the backend returns 403 CONNECTION_REQUIRED for scout<->athlete pairs.
Future<(String?, String?)> startConversationResult(WidgetRef ref, int participantId) async {
  try {
    final resp = await ref.read(dioProvider).post('/me/conversations', data: {'participant_id': participantId});
    return (resp.data['data']?['id']?.toString(), null);
  } on DioException catch (e) {
    final code = e.response?.data?['error']?['code']?.toString();
    final message = e.response?.data?['error']?['message']?.toString();
    if (code == 'CONNECTION_REQUIRED') {
      return (null, message ?? 'Connect and get accepted before chatting.');
    }
    return (null, message ?? 'Could not start chat.');
  }
}
