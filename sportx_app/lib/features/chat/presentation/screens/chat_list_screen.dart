import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text('Messages',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
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
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(conversationsProvider),
              child: async.when(
                loading: () => const ChatListSkeleton(),
                error: (e, _) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(ApiException.messageFor(e), style: const TextStyle(color: AppColors.textSecondary)),
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
                          Text('No conversations found', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                        ])),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: chats.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
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
    final initial = chat.title.isNotEmpty ? chat.title[0].toUpperCase() : 'C';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      leading: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE9A8), Color(0xFFFFC107), Color(0xFFF5B400)],
          ),
        ),
        alignment: Alignment.center,
        child: Text(initial,
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(chat.title,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.ink),
                overflow: TextOverflow.ellipsis),
          ),
          Text(chat.lastMessageAt ?? '',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
        ],
      ),
      subtitle: Text(chat.lastMessage ?? 'No messages yet',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => context.push('/chat-screen', extra: {'id': chat.id, 'name': chat.title, 'avatar': ''}),
    );
  }
}
