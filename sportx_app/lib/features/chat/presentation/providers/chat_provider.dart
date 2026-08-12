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

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      body: (json['body'] ?? '').toString(),
      senderId: (sender?['id'] ?? json['sender_user_id'])?.toString() ?? '',
      senderName: (sender?['name'] ?? 'User').toString(),
      createdAt: json['created_at'] as String?,
    );
  }
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
  try {
    final resp = await ref.read(dioProvider).post('/me/conversations', data: {'participant_id': participantId});
    return resp.data['data']?['id']?.toString();
  } on DioException {
    return null;
  }
}
