import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(conversationsProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(conversationsProvider);
    final query = _searchController.text.toLowerCase();
    final chats = (async.valueOrNull ?? [])
        .where((c) => c.title.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Messages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(LucideIcons.search, color: AppColors.textTertiary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(conversationsProvider),
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$e', style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: () => ref.invalidate(conversationsProvider), child: const Text('Retry')),
                  ]),
                ),
                data: (_) => chats.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 200),
                        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(LucideIcons.messageCircle, size: 64, color: AppColors.textTertiary),
                          const SizedBox(height: 16),
                          Text('No conversations found', style: TextStyle(color: AppColors.textSecondary)),
                        ])),
                      ])
                    : ListView.separated(
                        itemCount: chats.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                        itemBuilder: (context, index) => _buildChatTile(chats[index]),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(ConversationItem chat) {
    final hasUnread = (chat.lastMessage?.isNotEmpty ?? false);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: const CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary,
        child: Icon(LucideIcons.user, color: Colors.white),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(chat.title,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                overflow: TextOverflow.ellipsis),
          ),
          Text(chat.lastMessageAt ?? '',
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ],
      ),
      subtitle: Text(chat.lastMessage ?? 'No messages yet',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => context.push('/chat-screen', extra: {'id': chat.id, 'name': chat.title, 'avatar': ''}),
    );
  }
}
