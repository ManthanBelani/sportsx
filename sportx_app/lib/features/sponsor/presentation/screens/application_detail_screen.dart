import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ApplicationDetailScreen extends StatelessWidget {
  const ApplicationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aryan Patel's Application"),
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
            Text('Applied to: U-16 Cricket Kit', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('Date: 20 Jul 2026', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 24),
            Text('Pitch Note:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '"I\'ve represented my state at the U-14 level and am looking for support to compete at national tournaments. I\'m dedicated to improving my game and would love to represent your brand."',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/athlete-profile-view'),
                child: const Text('View Full Profile'),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to shortlist')));
                    },
                    icon: const Icon(Icons.star),
                    label: const Text('Shortlist'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application rejected')));
                      context.pop();
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Reply'),
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
