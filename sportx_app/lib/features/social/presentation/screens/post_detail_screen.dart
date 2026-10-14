import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/social/presentation/providers/posts_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sportx_app/core/config/api_config.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  String? _replyToId;
  String? _replyToName;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) { SnackBarUtils.showError(context, 'Please enter a comment'); return; }
    _commentController.clear();
    final ok = await commentOnPost(ref, widget.postId, text, parentId: _replyToId);
    setState(() { _replyToId = null; _replyToName = null; });
    if (mounted) {
      SnackBarUtils.showError(context, ok ? 'Comment posted!' : 'Failed to comment');
    }
  }

  void _sharePost(String author, String? body) {
    final url = '${ApiConfig.webBaseUrl}/post-detail/${widget.postId}';
    Share.share('Check this out on SportX by $author\n$url${body != null && body.isNotEmpty ? '\n\n"${body.length > 120 ? '${body.substring(0, 120)}…' : body}"' : ''}');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(postDetailProvider(widget.postId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        title: Text('Post',
            style: GoogleFonts.sora(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        actions: [
          Consumer(builder: (context, ref, _) {
            final post = ref.watch(postDetailProvider(widget.postId)).valueOrNull;
            return IconButton(
              icon: const Icon(LucideIcons.share2, color: AppColors.textPrimary),
              onPressed: post == null ? null : () => _sharePost(post.authorName, post.body),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: async.when(
              loading: () => const GenericDetailSkeleton(),
              error: (e, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(ApiException.messageFor(e), style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  PrimaryButton(
                      label: 'Retry',
                      onPressed: () =>
                          ref.invalidate(postDetailProvider(widget.postId))),
                ]),
              ),
              data: (post) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        const CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.yellow,
                            child: Icon(LucideIcons.user, color: AppColors.ink)),
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
                      child: SectionHeader(
                          title: 'Comments (${post.commentsCount})'),
                    ),
                    _CommentsList(
                      postId: widget.postId,
                      onReply: (id, name) => setState(() { _replyToId = id; _replyToName = name; }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_replyToName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppColors.yellowTint,
              child: Row(children: [
                Expanded(child: Text('Replying to $_replyToName', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                GestureDetector(onTap: () => setState(() { _replyToId = null; _replyToName = null; }), child: const Icon(LucideIcons.x, size: 16)),
              ]),
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
        Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w500)),
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
                  hintText: _replyToName != null ? 'Reply to $_replyToName...' : 'Write a comment...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _submitComment(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
              child: IconButton(icon: const Icon(LucideIcons.sendHorizontal, color: AppColors.ink, size: 20), onPressed: _submitComment),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsList extends ConsumerWidget {
  final String postId;
  final void Function(String id, String name) onReply;
  const _CommentsList({required this.postId, required this.onReply});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(postCommentsProvider(postId));
    return async.when(
      loading: () => const Padding(padding: EdgeInsets.all(16), child: Text('Loading comments...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
      error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text(ApiException.messageFor(e), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
      data: (items) {
        if (items.isEmpty) {
          return const Padding(padding: EdgeInsets.all(16), child: Text('Be the first to comment.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)));
        }
        return Column(
          children: items.map((c) {
            final user = c['user'] as Map<String, dynamic>?;
            final name = (user?['name'] ?? 'User').toString();
            final body = (c['body'] ?? '').toString();
            final id = c['id'].toString();
            return ListTile(
              dense: true,
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text(body, style: const TextStyle(fontSize: 13)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(LucideIcons.reply, size: 16), onPressed: () => onReply(id, name)),
                IconButton(icon: const Icon(LucideIcons.trash2, size: 16), onPressed: () async {
                  final ok = await deleteComment(ref, postId, id);
                  if (context.mounted && !ok) SnackBarUtils.showError(context, 'Failed to delete comment');
                }),
              ]),
            );
          }).toList(),
        );
      },
    );
  }
}