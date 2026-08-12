import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/enquiry_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class EnquiryDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const EnquiryDetailScreen({super.key, required this.id});

  @override
  ConsumerState<EnquiryDetailScreen> createState() => _EnquiryDetailScreenState();
}

class _EnquiryDetailScreenState extends ConsumerState<EnquiryDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(enquiryDetailProvider(widget.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(async.maybeWhen(data: (e) => e.athleteName, orElse: () => 'Enquiry'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMessageBubble(
                    sender: enquiry.athleteName,
                    message: enquiry.message,
                    time: enquiry.createdAt ?? '',
                    isMe: false,
                  ),
                  ...enquiry.messages.map((m) => _buildMessageBubble(
                        sender: m.sender,
                        message: m.body,
                        time: m.createdAt ?? '',
                        isMe: m.isMe,
                      )),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: 'Type a reply...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.sendHorizontal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String sender,
    required String message,
    required String time,
    required bool isMe,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(sender, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message),
          ),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }
}
