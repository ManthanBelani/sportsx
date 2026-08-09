import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/theme/colors.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();

  // Mock post data
  final Map<String, dynamic> _post = {
    'id': '1',
    'authorName': 'Aryan Patel',
    'authorAvatar': 'https://i.pravatar.cc/150?img=11',
    'timeAgo': '2h ago',
    'content': 'Great practice session today with the U-14 team! 🏏 Focused on batting technique and footwork. Keep pushing, champions!',
    'imageUrl': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&h=400&fit=crop',
    'likes': 24,
    'comments': 8,
    'isLiked': false,
  };

  // Mock comments data
  final List<Map<String, dynamic>> _comments = [
    {
      'id': 'c1',
      'authorName': 'Rohit Sharma',
      'authorAvatar': 'https://i.pravatar.cc/150?img=3',
      'text': 'Great work! Keep it up! 💪',
      'timeAgo': '1h ago',
      'likes': 5,
    },
    {
      'id': 'c2',
      'authorName': 'Coach Vikram',
      'authorAvatar': 'https://i.pravatar.cc/150?img=12',
      'text': 'Excellent technique improvement. Very proud of the team!',
      'timeAgo': '45m ago',
      'likes': 8,
    },
    {
      'id': 'c3',
      'authorName': 'Priya Patel',
      'authorAvatar': 'https://i.pravatar.cc/150?img=5',
      'text': 'Looking forward to the next session!',
      'timeAgo': '30m ago',
      'likes': 2,
    },
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostHeader(),
                  _buildPostContent(),
                  _buildPostActions(),
                  const Divider(),
                  _buildCommentsSection(),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(_post['authorAvatar']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _post['authorName'],
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                Text(
                  _post['timeAgo'],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _post['content'],
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        if (_post['imageUrl'] != null) ...[
          const SizedBox(height: 12),
          Image.network(
            _post['imageUrl'],
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          ),
        ],
      ],
    );
  }

  Widget _buildPostActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildActionChip(
            icon: _post['isLiked'] ? Icons.favorite : Icons.favorite_border,
            label: '${_post['likes']}',
            color: _post['isLiked'] ? AppColors.error : AppColors.textSecondary,
            onTap: () {
              setState(() {
                _post['isLiked'] = !_post['isLiked'];
                _post['likes'] += _post['isLiked'] ? 1 : -1;
              });
            },
          ),
          const SizedBox(width: 16),
          _buildActionChip(
            icon: Icons.chat_bubble_outline,
            label: '${_post['comments']}',
            color: AppColors.textSecondary,
            onTap: () {},
          ),
          const SizedBox(width: 16),
          _buildActionChip(
            icon: Icons.share_outlined,
            label: 'Share',
            color: AppColors.textSecondary,
            onTap: () {},
          ),
          const SizedBox(width: 16),
          _buildActionChip(
            icon: Icons.bookmark_border,
            label: 'Save',
            color: AppColors.textSecondary,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Comments (${_comments.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _comments.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            return _buildCommentItem(_comments[index]);
          },
        ),
      ],
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(comment['authorAvatar']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['authorName'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment['timeAgo'],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment['text']),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Row(
                        children: [
                          Icon(Icons.favorite_border, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${comment['likes']}',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Reply',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _commentController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _submitComment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _comments.add({
        'id': 'c${_comments.length + 1}',
        'authorName': 'Aryan Patel',
        'authorAvatar': 'https://i.pravatar.cc/150?img=11',
        'text': text,
        'timeAgo': 'Just now',
        'likes': 0,
      });
      _post['comments'] += 1;
      _commentController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment posted!')),
    );
  }
}
