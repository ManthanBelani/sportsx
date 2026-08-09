import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShortlistScreen extends StatelessWidget {
  const ShortlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shortlist'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildShortlistCard(context, 'Aryan Patel', 'Cricket', 'Strong technique, follow up next week'),
          const SizedBox(height: 12),
          _buildShortlistCard(context, 'Meera Shah', 'Badminton', '—'),
        ],
      ),
    );
  }

  Widget _buildShortlistCard(BuildContext context, String name, String sport, String note) {
    return InkWell(
      onTap: () => context.push('/athlete-profile-view'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.amber.withOpacity(0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text('$name · $sport', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Note: "$note"', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
