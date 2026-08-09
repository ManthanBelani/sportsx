import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SponsorshipPostingScreen extends StatelessWidget {
  const SponsorshipPostingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Sponsorship Listing'),
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
            const TextField(decoration: InputDecoration(labelText: 'Title', hintText: 'e.g. U-16 Cricket Kit')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Sport')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Eligibility', hintText: 'State-level players only')),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Benefits Offered', hintText: 'Free kit + ₹5000 stipend / month'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Deadline', hintText: '📅 30 Sep 2026')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sponsorship Published!')));
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
