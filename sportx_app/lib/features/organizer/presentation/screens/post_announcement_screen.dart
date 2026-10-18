import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// OR.14 Post Announcement (P1) — update to registrants / followers.
class PostAnnouncementScreen extends StatefulWidget {
  const PostAnnouncementScreen({super.key});

  @override
  State<PostAnnouncementScreen> createState() => _PostAnnouncementScreenState();
}

class _PostAnnouncementScreenState extends State<PostAnnouncementScreen> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  String? _event;

  static const _events = [
    'State U-19 Championship',
    'Summer Cricket Camp',
    'District Football Trials',
  ];

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPost = _title.text.trim().isNotEmpty &&
        _message.text.trim().isNotEmpty;
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
                        labelText: 'Title',
                        hintText: 'e.g. Venue changed for finals'),
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
                  DropdownButtonFormField<String>(
                    initialValue: _event,
                    decoration: const InputDecoration(
                        labelText: 'Target event (optional)'),
                    items: _events
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _event = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(LucideIcons.info,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _event == null
                              ? 'Goes to all your followers'
                              : 'Goes to registrants of $_event',
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
                label: 'Publish announcement',
                icon: LucideIcons.send,
                onPressed: canPost
                    ? () {
                        SnackBarUtils.showSuccess(
                            context, 'Announcement published');
                        Navigator.of(context).maybePop();
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
