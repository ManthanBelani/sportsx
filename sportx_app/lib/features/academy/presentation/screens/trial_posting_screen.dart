import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TrialPostingScreen extends StatelessWidget {
  const TrialPostingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a New Trial'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Save'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Trial Name', hintText: 'e.g. U-14 Cricket Trial')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Sport')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Date & Time', hintText: '📅 15 Aug 2026')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Venue')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Eligibility', hintText: 'e.g. Boys, U-14')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Entry Fee', hintText: '₹200')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Required Docs', hintText: 'e.g. Aadhaar, Photo')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Contact Number')),
            const SizedBox(height: 32),
            Row(
              children: [
                const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Radio(value: 0, groupValue: 1, onChanged: (v){}),
                const Text('Draft'),
                Radio(value: 1, groupValue: 1, onChanged: (v){}),
                const Text('Published'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trial Published!')));
                  context.pop();
                },
                child: const Text('Save & Publish'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
