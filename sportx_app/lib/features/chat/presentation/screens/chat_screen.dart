import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final String chatAvatar;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.chatAvatar,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await sendMessage(ref, widget.chatId, text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(conversationDetailProvider(widget.chatId));
    final currentUserId = ref.watch(authProvider).user?.id.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text(widget.chatName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: Column(
        children: [
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$e', style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => ref.invalidate(conversationDetailProvider(widget.chatId)), child: const Text('Retry')),
                ]),
              ),
              data: (messages) => messages.isEmpty
                  ? const Center(child: Text('Start a conversation', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final m = messages[index];
                        return _buildMessageBubble(m, m.senderId == currentUserId);
                      },
                    ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.body, style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 14)),
            if (message.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(message.createdAt!,
                  style: TextStyle(color: isMe ? Colors.white70 : AppColors.textTertiary, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(LucideIcons.sendHorizontal, color: Colors.white, size: 20),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
