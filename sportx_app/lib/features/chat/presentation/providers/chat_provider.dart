import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/safety_reminder.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class ConversationItem {
  final String id;
  final String title;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;

  ConversationItem({
    required this.id,
    required this.title,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
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
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatMessage {
  final String id;
  final String body;
  final String senderId;
  final String senderName;
  final String? createdAt;
  final bool isSystem;

  ChatMessage({
    required this.id,
    required this.body,
    required this.senderId,
    required this.senderName,
    this.createdAt,
    this.isSystem = false,
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
      isSystem: (json['type'] ?? 'text').toString() == 'system',
    );
  }
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final y = local.year.toString();
  if (diff == 0) return '$hh:$mm';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return _weekdays[local.weekday - 1];
  return '$d-$m-$y';
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
  // Opening the thread clears the server-side unread counter so the chat
  // list stops showing this conversation as unread.
  markConversationRead(ref, id);
  // API returns newest first; reverse for chronological display (oldest first)
  return messages.map(ChatMessage.fromJson).toList().reversed.toList();
});

/// Marks a conversation read on the server (fire-and-forget — failures must
/// never block rendering the thread) and refreshes the unread badges.
Future<void> markConversationRead(Ref ref, String conversationId) async {
  try {
    await ref.read(dioProvider).post('/conversations/$conversationId/read');
    ref.invalidate(conversationsProvider);
  } on DioException {
    // Best-effort: unread badge stays until the next visit.
  }
}

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

/// Silently poll for messages typed by the other side (riverpod runs this in
/// the background). The 4s cadence trades a little latency for battery; the
/// FCM message push, once wired to a foreground handler, will refresh faster.
Timer? _chatPollTimer;

void startChatPolling(WidgetRef ref, String conversationId) {
  stopChatPolling();
  _chatPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
    ref.invalidate(conversationDetailProvider(conversationId));
    ref.invalidate(conversationsProvider);
  });
}

void stopChatPolling() {
  _chatPollTimer?.cancel();
  _chatPollTimer = null;
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
    if (code == 'GUARDIAN_REQUIRED') {
      return (null, 'GUARDIAN_REQUIRED: ${message ?? 'Minor chat requires guardian consent.'}');
    }
    if (code == 'CONNECTION_REQUIRED') {
      return (null, message ?? 'Connect and get accepted before chatting.');
    }
    return (null, message ?? 'Could not start chat.');
  }
}

/// Helper to handle chat initiation errors. If [err] is GUARDIAN_REQUIRED,
/// displays an explanatory dialog that routes the user to /guardian-consent.
/// Otherwise displays a snackbar with the error.
Future<void> handleChatStartError(BuildContext context, String? err) async {
  if (!context.mounted || err == null) return;
  if (err.startsWith('GUARDIAN_REQUIRED') || err.contains('guardian consent')) {
    final proceed = await showConfirmDialog(
      context: context,
      title: 'Parental Consent Required',
      message: 'Athletes under 18 must have verified parental or guardian consent before chatting with other members. Would you like to provide or verify guardian consent now?',
      confirmText: 'Verify Consent',
      cancelText: 'Not Now',
    );
    if (proceed == true && context.mounted) {
      context.push('/guardian-consent');
    }
    return;
  }
  SnackBarUtils.showError(context, err);
}

/// Starts a conversation with safety reminder for minors.
/// Returns (conversationId, errorMessage) or (null, 'cancelled') if user cancels.
Future<(String?, String?)> startConversationWithSafetyCheck(
  BuildContext context,
  WidgetRef ref,
  int participantId,
) async {
  // Check if user is minor and show safety reminder
  final isMinor = await ref.read(isMinorProvider.future);
  if (isMinor && context.mounted) {
    final confirmed = await showSafetyReminder(
      context,
      feature: 'chat',
      customMessage: 'Remember: only chat with people you know in real life.',
    );
    if (!confirmed) {
      return (null, 'cancelled');
    }
  }

  return startConversationResult(ref, participantId);
}
