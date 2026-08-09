import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultsPublishingScreen extends StatelessWidget {
  const ResultsPublishingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'u14', child: Text('U-14')),
                DropdownMenuItem(value: 'u16', child: Text('U-16')),
                DropdownMenuItem(value: 'u18', child: Text('U-18')),
              ],
              onChanged: (v) {},
            ),
            const SizedBox(height: 24),
            const TextField(
              decoration: InputDecoration(
                labelText: '🥇 Winner',
                hintText: 'Team Titans',
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: '🥈 Runner-up',
                hintText: 'Team Strikers',
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: '🥉 3rd Place',
                hintText: 'Team Falcons',
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload),
              label: const Text('Upload Bracket Image'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Results published!')));
                  context.pop();
                },
                child: const Text('Publish Results'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
