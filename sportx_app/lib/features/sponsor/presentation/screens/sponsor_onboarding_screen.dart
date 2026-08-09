import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SponsorOnboardingScreen extends StatelessWidget {
  const SponsorOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your brand profile'),
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
            const TextField(decoration: InputDecoration(labelText: 'Brand Name', hintText: 'ProGear Sports')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Logo', hintText: '+ Upload Logo')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'sportswear', child: Text('Sportswear')),
                DropdownMenuItem(value: 'energy_drink', child: Text('Energy Drink')),
                DropdownMenuItem(value: 'equipment', child: Text('Equipment')),
              ],
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Verification Docs', hintText: '+ Upload Documents')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Submitted for Review')));
                  context.go('/sponsor-dashboard'); // Note: Sponsor dashboard isn't requested yet but placeholder
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
