import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ApplicationsInboxScreen extends StatelessWidget {
  const ApplicationsInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications Inbox'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildApplicationCard(context, 'Aryan Patel', 'Cricket', 'U-16 Cricket Kit', '20 Jul 2026', true),
          const SizedBox(height: 12),
          _buildApplicationCard(context, 'Meera Shah', 'Badminton', 'Badminton Prodigy Fund', '18 Jul 2026', false),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(BuildContext context, String name, String sport, String listing, String date, bool isNew) {
    return InkWell(
      onTap: () => context.push('/application-detail'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: isNew ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('$name · $sport', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (isNew) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Applied to: $listing', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('Date: $date', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
