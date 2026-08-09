import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CoachOnboardingScreen extends StatelessWidget {
  const CoachOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your coach profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Sport(s) Coached', hintText: 'Cricket')),
            const SizedBox(height: 24),
            Text('Certifications', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(child: Text('BCCI Level 2 Certificate')),
                  Icon(Icons.check_circle, color: Colors.green[400]),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add Certification'),
            ),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Years of Experience', hintText: '8')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go('/edit-coach-profile'),
                child: const Text('Next'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
