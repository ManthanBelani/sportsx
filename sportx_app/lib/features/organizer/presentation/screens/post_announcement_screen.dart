import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/features/social/presentation/providers/posts_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// OR.14 Post Announcement — published to the organizer's followers
/// (POST /posts with visibility=followers).
class PostAnnouncementScreen extends ConsumerStatefulWidget {
  const PostAnnouncementScreen({super.key});

  @override
  ConsumerState<PostAnnouncementScreen> createState() => _PostAnnouncementScreenState();
}

class _PostAnnouncementScreenState extends ConsumerState<PostAnnouncementScreen> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  int? _eventId;
  String? _eventName;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_sending) return;
    final title = _title.text.trim();
    final message = _message.text.trim();
    if (title.isEmpty || message.isEmpty) {
      SnackBarUtils.showError(context, 'Add a title and a message first');
      return;
    }

    setState(() => _sending = true);
    try {
      // The event context becomes the first line so the audience knows what
      // the announcement is about.
      final body = _eventName == null
          ? '$title\n\n$message'
          : '$_eventName — $title\n\n$message';

      await ref.read(dioProvider).post('/posts', data: {
        'body': body,
        'visibility': 'followers',
        'audience': 'followers',
      });

      ref.invalidate(filteredPostsFeedProvider(''));
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Announcement published to your followers');
      context.pop();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e, 'Could not publish the announcement');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournaments = ref.watch(myTournamentsProvider);
    final canPost = _title.text.trim().isNotEmpty && _message.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Post Announcement', showBack: true),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SportXCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _title,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                        labelText: 'Title', hintText: 'e.g. Venue changed for finals'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _message,
                    maxLines: 5,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Write your update…',
                        alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _eventId,
                    decoration: const InputDecoration(
                        labelText: 'Target event (optional)'),
                    items: tournaments.items
                        .map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.title,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _eventId = v;
                      _eventName = tournaments.items
                          .where((t) => t.id == v)
                          .map((t) => t.title)
                          .firstOrNull;
                    }),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(LucideIcons.info,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _eventName == null
                              ? 'Goes to all your followers'
                              : 'Goes to followers of $_eventName',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: _sending ? 'Publishing…' : 'Publish announcement',
                icon: LucideIcons.send,
                onPressed: canPost && !_sending ? _publish : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
