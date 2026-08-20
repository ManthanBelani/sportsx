import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/form_page_template.dart';
import 'package:sportx_app/shared/providers/activity_provider.dart';

class EnquireScreen extends ConsumerStatefulWidget {
  final String title;
  const EnquireScreen({super.key, required this.title});

  @override
  ConsumerState<EnquireScreen> createState() => _EnquireScreenState();
}

class _EnquireScreenState extends ConsumerState<EnquireScreen> {
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(dioProvider).post('/enquiries', data: {
        'subject': 'Enquiry about ${widget.title}',
        'message': _messageController.text.trim(),
        'recipient_name': widget.title,
      });
      ref.invalidate(activityProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enquiry Sent Successfully!')),
        );
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.fromDio(e).message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send enquiry. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return FormPageTemplate(
      title: 'Enquire with ${widget.title}',
      autoFilledProfile: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name: ${user?.name ?? 'Loading...'}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Phone: ${user?.phone ?? 'N/A'}'),
          Text('Role: ${user?.role ?? 'Athlete'}'),
        ],
      ),
      formFields: [
        Text(
          'Message',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 5,
          enabled: !_submitting,
          decoration: InputDecoration(
            hintText: 'I would like to know more about the admission process...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
      ctaText: _submitting ? 'Sending...' : 'Send Enquiry',
      onSubmit: _submitting ? () {} : _submit,
    );
  }
}
