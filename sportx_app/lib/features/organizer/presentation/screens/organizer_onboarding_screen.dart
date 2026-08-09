import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrganizerOnboardingScreen extends StatelessWidget {
  const OrganizerOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your organizer profile'),
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
            const TextField(decoration: InputDecoration(labelText: 'Organization Name', hintText: 'SportsFed Guj')),
            const SizedBox(height: 24),
            const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Radio(value: 0, groupValue: 0, onChanged: (v){}),
                const Text('Federation'),
                Radio(value: 1, groupValue: 0, onChanged: (v){}),
                const Text('Club'),
                Radio(value: 2, groupValue: 0, onChanged: (v){}),
                const Text('Other'),
              ],
            ),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Verification Docs', hintText: '+ Upload Documents')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Submitted for Review')));
                  context.go('/organizer-dashboard');
                },
                child: const Text('Submit'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
