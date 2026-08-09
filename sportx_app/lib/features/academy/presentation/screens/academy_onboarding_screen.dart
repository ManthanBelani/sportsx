import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AcademyOnboardingScreen extends StatelessWidget {
  const AcademyOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your academy'),
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
            const TextField(decoration: InputDecoration(labelText: 'Academy Name', hintText: 'Elite Cricket Acad')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Sport(s)', hintText: 'Cricket')),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add Sport'),
            ),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'City', hintText: 'Ahmedabad')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go('/edit-academy-profile'),
                child: const Text('Next'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
