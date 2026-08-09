import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TournamentPostingScreen extends StatelessWidget {
  const TournamentPostingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament'),
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
            const TextField(decoration: InputDecoration(labelText: 'Tournament Name', hintText: 'e.g. U-16 State Cup')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Format'),
              items: const [
                DropdownMenuItem(value: 'knockout', child: Text('Knockout')),
                DropdownMenuItem(value: 'league', child: Text('League')),
              ],
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Dates', hintText: '📅 20–25 Aug 2026')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Venue')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Entry Fee', hintText: 'e.g. ₹500 / team')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Prize Pool', hintText: 'e.g. ₹50,000')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Categories', hintText: 'e.g. U-14, U-16')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tournament Published!')));
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
