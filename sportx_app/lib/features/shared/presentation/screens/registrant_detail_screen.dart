import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegistrantDetailScreen extends StatelessWidget {
  const RegistrantDetailScreen({super.key});

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Name: Aryan Patel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Age: 14 · Cricket · Under-14'),
            const SizedBox(height: 8),
            const Text('Contact: +91 98XXXXXXXX'),
            const SizedBox(height: 32),
            Text('Submitted Documents', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Aadhaar Card'),
              trailing: TextButton(onPressed: (){}, child: const Text('View')),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Passport Photo'),
              trailing: TextButton(onPressed: (){}, child: const Text('View')),
              contentPadding: EdgeInsets.zero,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Rejected.')));
                      context.pop();
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as Verified.')));
                      context.pop();
                    },
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Mark as Verified'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
