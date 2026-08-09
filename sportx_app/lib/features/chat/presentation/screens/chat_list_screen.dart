import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/theme/colors.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<Map<String, dynamic>> _chats = [
    {
      'id': '1',
      'name': 'Rohit Sharma',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'lastMessage': 'Great practice session today!',
      'timestamp': '2m ago',
      'unread': 2,
      'sport': 'Cricket',
    },
    {
      'id': '2',
      'name': 'Priya Patel',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'lastMessage': 'Are you coming to the tournament?',
      'timestamp': '15m ago',
      'unread': 0,
      'sport': 'Badminton',
    },
    {
      'id': '3',
      'name': 'Akash Kumar',
      'avatar': 'https://i.pravatar.cc/150?img=8',
      'lastMessage': 'Check out this training video',
      'timestamp': '1h ago',
      'unread': 1,
      'sport': 'Football',
    },
    {
      'id': '4',
      'name': 'Sneha Reddy',
      'avatar': 'https://i.pravatar.cc/150?img=9',
      'lastMessage': 'Thanks for the tips!',
      'timestamp': '3h ago',
      'unread': 0,
      'sport': 'Tennis',
    },
    {
      'id': '5',
      'name': 'Coach Vikram',
      'avatar': 'https://i.pravatar.cc/150?img=12',
      'lastMessage': 'Next practice at 6 AM',
      'timestamp': 'Yesterday',
      'unread': 0,
      'sport': 'Athletics',
    },
    {
      'id': '6',
      'name': 'Delhi Sports Academy',
      'avatar': 'https://i.pravatar.cc/150?img=15',
      'lastMessage': 'Your registration is confirmed',
      'timestamp': 'Yesterday',
      'unread': 0,
      'sport': 'Multi-sport',
    },
  ];

  List<Map<String, dynamic>> _filteredChats = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredChats = List.from(_chats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterChats(String query) {
    setState(() {
      _filteredChats = _chats
          .where((chat) => chat['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterChats,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _filterChats('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _filteredChats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'No conversations found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredChats.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                    itemBuilder: (context, index) {
                      final chat = _filteredChats[index];
                      return _buildChatTile(chat);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    final hasUnread = (chat['unread'] as int) > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(chat['avatar']),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              width: 12,
              height: 12,
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat['name'],
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            chat['timestamp'],
            style: TextStyle(
              fontSize: 12,
              color: hasUnread ? AppColors.primary : AppColors.textTertiary,
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              chat['lastMessage'],
              style: TextStyle(
                color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${chat['unread']}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        context.push('/chat-screen', extra: {
          'id': chat['id'],
          'name': chat['name'],
          'avatar': chat['avatar'],
        });
      },
    );
  }
}
