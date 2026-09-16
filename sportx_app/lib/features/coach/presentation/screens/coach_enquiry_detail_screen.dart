import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/providers/enquiry_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/core/utils/date_format_utils.dart';

class CoachEnquiryDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const CoachEnquiryDetailScreen({super.key, required this.id});

  @override
  ConsumerState<CoachEnquiryDetailScreen> createState() => _CoachEnquiryDetailScreenState();
}

class _CoachEnquiryDetailScreenState extends ConsumerState<CoachEnquiryDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  final List<String> _quickReplies = [
    'Yes, slots available',
    'Come for a free trial',
    'Share your number',
    'Classes start at 4 PM',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(dioProvider).put('/enquiries/${widget.id}/read');
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final ok = await replyEnquiry(ref, widget.id, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _replyController.clear();
      ref.read(enquiryInboxProvider.notifier).load();
      _scrollToBottom();
    } else {
      SnackBarUtils.showError(context, 'Failed to send message');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _useQuickReply(String reply) {
    _replyController.text = reply;
    _replyController.selection = TextSelection.fromPosition(
      TextPosition(offset: reply.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(enquiryDetailProvider(widget.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => context.pop(),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 20),
            ),
          ),
        ),
        title: const Text(
          'Enquiry',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
      body: async.when(
        loading: () => const CoachEnquiryDetailSkeleton(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(enquiryDetailProvider(widget.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (enquiry) => Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  _buildEnquirerCard(enquiry),
                  const SizedBox(height: 20),
                  _buildQuickReplies(),
                  const SizedBox(height: 20),
                  _buildMessageThread(enquiry),
                ],
              ),
            ),
            _buildReplyBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnquirerCard(Enquiry enquiry) {
    final isNew = enquiry.status == 'new' && !enquiry.isRead;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: enquiry.athletePhotoUrl != null
                ? ClipOval(
                    child: Image.network(
                      enquiry.athletePhotoUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(LucideIcons.user, color: AppColors.primary),
                    ),
                  )
                : const Icon(LucideIcons.user, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enquiry.athleteName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                if (enquiry.sport != null) ...[
                  Row(
                    children: [
                      const Icon(LucideIcons.circle, size: 10, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${enquiry.sport} •',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isNew)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFdbeafe),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'New',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _quickReplies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return OutlinedButton(
            onPressed: () => _useQuickReply(_quickReplies[index]),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(_quickReplies[index], style: const TextStyle(fontSize: 13)),
          );
        },
      ),
    );
  }

  Widget _buildMessageThread(Enquiry enquiry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMessageBubble(
          message: enquiry.message,
          time: DateFormatUtils.formatDisplayDate(enquiry.createdAt),
          isMe: false,
        ),
        ...enquiry.messages.map((m) => _buildMessageBubble(
              message: m.body,
              time: DateFormatUtils.formatDisplayDate(m.createdAt),
              isMe: m.isMe,
            )),
      ],
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required String time,
    required bool isMe,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isMe ? 12 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 12),
            ),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: isMe ? Colors.white : const Color(0xFF1F2937),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe) ...[
                    Icon(LucideIcons.clock, size: 10, color: AppColors.textSecondary),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: InputDecoration(
                hintText: 'Type your reply...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.send, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
