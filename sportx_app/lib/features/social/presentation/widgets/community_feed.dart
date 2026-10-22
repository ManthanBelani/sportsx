import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sportx_app/core/config/api_config.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/social/presentation/providers/posts_provider.dart';
import 'package:sportx_app/theme/colors.dart';

/// Card used by the home feed preview and the full /community page.
class CommunityPostCard extends StatelessWidget {
  final SocialPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onOpen;
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onOpen,
  });

  /// Overflow menu for a feed card — share is the one action the card can
  /// always honour (report/save live on the detail screen).
  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: const Icon(LucideIcons.share2, size: 20),
              title: Text(
                'Share post',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                final url = '${ApiConfig.webBaseUrl}/post-detail/${post.id}';
                Share.share(
                  post.body?.isNotEmpty == true
                      ? '${post.body}\n$url'
                      : 'Check this out on SportX\n$url',
                );
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.x, size: 20),
              title: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = post.authorAvatar;
    final image = post.imageUrl;
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D101415),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.yellowTint,
                    backgroundImage: (avatar != null && avatar.isNotEmpty)
                        ? NetworkImage(MediaUtils.resolveUrl(avatar))
                        : null,
                    child: (avatar == null || avatar.isEmpty)
                        ? Text(
                            post.authorName.isNotEmpty
                                ? post.authorName[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          post.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        if ((post.createdAt ?? '').isNotEmpty)
                          Text(
                            _humanizeTime(post.createdAt!),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(LucideIcons.moreHorizontal, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: () => _showActions(context),
                  ),
                ],
              ),
            ),
            if ((post.body ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text(
                  post.body!,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColors.ink,
                  ),
                ),
              ),
            if (image != null && image.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  MediaUtils.resolveUrl(image),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.surface,
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.image,
                      color: AppColors.textTertiary,
                      size: 32,
                    ),
                  ),
                ),
              ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.borderSoft,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  _FeedAction(
                    icon: LucideIcons.heart,
                    color: post.liked
                        ? Colors.redAccent
                        : AppColors.textSecondary,
                    filled: post.liked,
                    label: _compactNumber(post.likesCount),
                    onTap: onLike,
                  ),
                  _FeedAction(
                    icon: LucideIcons.messageCircle,
                    color: AppColors.textSecondary,
                    label: _compactNumber(post.commentsCount),
                    onTap: onComment,
                  ),
                  const Spacer(),
                  _FeedAction(
                    icon: LucideIcons.share2,
                    color: AppColors.textSecondary,
                    onTap: onOpen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool filled;
  final String? label;
  final VoidCallback onTap;
  const _FeedAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: color,
      ),
      icon: Icon(icon, size: 18, color: color, fill: filled ? 1.0 : null),
      label: label == null
          ? const SizedBox.shrink()
          : Text(
              label!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
    );
  }
}

String _humanizeTime(String raw) {
  final dt = DateTime.tryParse(raw);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.day}/${dt.month}';
}

String _compactNumber(int n) {
  if (n < 1000) return n.toString();
  if (n < 10000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '${(n / 1000).round()}K';
}
