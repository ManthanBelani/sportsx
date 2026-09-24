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
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

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
    if (text.isEmpty) { SnackBarUtils.showError(context, 'Please enter a comment'); return; }
    _commentController.clear();
    final ok = await commentOnPost(ref, widget.postId, text);
    if (mounted) {
      SnackBarUtils.showError(context, ok ? 'Comment posted!' : 'Failed to comment');
    }
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
                  hintText: 'Write a comment...',
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