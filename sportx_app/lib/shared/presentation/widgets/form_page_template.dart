import 'package:flutter/material.dart';

class FormPageTemplate extends StatefulWidget {
  final String title;
  final Widget? autoFilledProfile;
  final List<Widget> formFields;
  final String ctaText;
  final VoidCallback onSubmit;
  final String confirmText;

  const FormPageTemplate({
    super.key,
    required this.title,
    this.autoFilledProfile,
    required this.formFields,
    required this.ctaText,
    required this.onSubmit,
    this.confirmText = 'I confirm the details are correct',
  });

  @override
  State<FormPageTemplate> createState() => _FormPageTemplateState();
}

class _FormPageTemplateState extends State<FormPageTemplate> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.autoFilledProfile != null) ...[
              Text('Your Profile (auto-filled)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: widget.autoFilledProfile!,
              ),
              const SizedBox(height: 24),
            ],

            ...widget.formFields,

            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: _confirmed,
                  onChanged: (v) => setState(() => _confirmed = v ?? false),
                ),
                Expanded(
                  child: Text(widget.confirmText),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _confirmed ? widget.onSubmit : null,
                child: Text(widget.ctaText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
