import 'package:flutter/material.dart';

class FormPageTemplate extends StatelessWidget {
  final String title;
  final Widget? autoFilledProfile;
  final List<Widget> formFields;
  final String ctaText;
  final VoidCallback onSubmit;

  const FormPageTemplate({
    super.key,
    required this.title,
    this.autoFilledProfile,
    required this.formFields,
    required this.ctaText,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (autoFilledProfile != null) ...[
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
                child: autoFilledProfile!,
              ),
              const SizedBox(height: 24),
            ],
            
            ...formFields,
            
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(value: true, onChanged: (v) {}),
                const Expanded(
                  child: Text('I confirm the details are correct'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: onSubmit,
                child: Text(ctaText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
