import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/social/presentation/providers/posts_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Organizer "Create Poll" — the design board lists a Poll tile on the
/// organizer's Create tab. The API has no dedicated poll entity yet, so the
/// poll is published as a formatted feed post (question + options) that reads
/// like a poll on the feed.
class CreatePollScreen extends ConsumerStatefulWidget {
  const CreatePollScreen({super.key});

  @override
  ConsumerState<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends ConsumerState<CreatePollScreen> {
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _posting = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionCtrls.length >= 6) return;
    setState(() => _optionCtrls.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionCtrls.length <= 2) return;
    setState(() {
      _optionCtrls[index].dispose();
      _optionCtrls.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final question = _questionCtrl.text.trim();
    final options = _optionCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (question.isEmpty) {
      SnackBarUtils.showError(context, 'Please add a poll question.');
      return;
    }
    if (options.length < 2) {
      SnackBarUtils.showError(context, 'Add at least two options.');
      return;
    }

    setState(() => _posting = true);
    try {
      final body = StringBuffer('📊 Poll: $question\n\n');
      for (var i = 0; i < options.length; i++) {
        body.writeln('${i + 1}. ${options[i]}');
      }
      body.write('\nReply with your vote!');
      await ref
          .read(dioProvider)
          .post('/posts', data: {'body': body.toString()});
      // The poll lands on the feed — refresh every feed surface that shows it.
      ref.invalidate(postsFeedProvider);
      ref.invalidate(filteredPostsFeedProvider(''));
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Poll published to the feed');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e, 'Could not publish the poll.');
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Poll',
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Question',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _questionCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. Which city should host the next tournament?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Options',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_optionCtrls.length < 6)
                GestureDetector(
                  onTap: _addOption,
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.plus,
                        size: 14,
                        color: AppColors.primaryDarker,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Add option',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDarker,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _optionCtrls.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.yellowTint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDarker,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _optionCtrls[i],
                      decoration: InputDecoration(
                        hintText: 'Option ${i + 1}',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  if (_optionCtrls.length > 2)
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () => _removeOption(i),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Polls are published to your feed as a post — followers reply with their vote.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: PrimaryButton(
            label: _posting ? 'Publishing…' : 'Publish Poll',
            icon: LucideIcons.barChart2,
            onPressed: _posting ? null : _submit,
          ),
        ),
      ),
    );
  }
}
