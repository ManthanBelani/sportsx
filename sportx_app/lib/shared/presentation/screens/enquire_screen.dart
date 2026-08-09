import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/shared/presentation/widgets/form_page_template.dart';

class EnquireScreen extends StatelessWidget {
  final String title;
  const EnquireScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return FormPageTemplate(
      title: 'Enquire with $title',
      autoFilledProfile: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name: John Doe', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Phone: +91 9876543210'),
          Text('Role: Athlete (Cricket)'),
        ],
      ),
      formFields: [
        Text(
          'Message',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'I would like to know more about the admission process...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
      ctaText: 'Send Enquiry',
      onSubmit: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enquiry Sent Successfully!')),
        );
        context.pop();
      },
    );
  }
}
