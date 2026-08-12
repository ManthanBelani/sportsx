import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/social/presentation/providers/posts_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    final ok = await commentOnPost(ref, widget.postId, text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Comment posted!' : 'Failed to comment')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(postDetailProvider(widget.postId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
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
                  ElevatedButton(onPressed: () => ref.invalidate(postDetailProvider(widget.postId)), child: const Text('Retry')),
                ]),
              ),
              data: (post) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        const CircleAvatar(radius: 24, backgroundColor: AppColors.primary, child: Icon(LucideIcons.user, color: Colors.white)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
                          if (post.createdAt != null) Text(post.createdAt!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ])),
                      ]),
                    ),
                    if (post.body != null && post.body!.isNotEmpty)
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(post.body!, style: const TextStyle(color: AppColors.textPrimary))),
                    if (post.imageUrl != null) ...[
                      const SizedBox(height: 12),
                      Image.network(post.imageUrl!, width: double.infinity, height: 300, fit: BoxFit.cover),
                    ],
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        _action(LucideIcons.heart, '${post.likesCount}', post.liked ? AppColors.error : AppColors.textSecondary, () => togglePostLike(ref, widget.postId)),
                        const SizedBox(width: 16),
                        _action(LucideIcons.messageCircle, '${post.commentsCount}', AppColors.textSecondary, () {}),
                      ]),
                    ),
                    const Divider(color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Comments (${post.commentsCount})', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _submitComment(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: IconButton(icon: const Icon(LucideIcons.sendHorizontal, color: Colors.white, size: 20), onPressed: _submitComment),
            ),
          ],
        ),
      ),
    );
  }
}
