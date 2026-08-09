import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AthleteProfileViewScreen extends StatelessWidget {
  const AthleteProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aryan Patel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 12),
            Text('Aryan Patel', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Cricket · Under-14', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('🏆 Achievements', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.emoji_events, color: Colors.amber),
              title: Text('State-level U-14 selection 2025'),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('🎞 Media Gallery', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, i) => Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Shortlist')));
                    },
                    icon: const Icon(Icons.star),
                    label: const Text('Shortlist'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
