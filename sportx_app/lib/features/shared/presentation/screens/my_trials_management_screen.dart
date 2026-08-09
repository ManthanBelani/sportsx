import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyTrialsManagementScreen extends StatelessWidget {
  const MyTrialsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trials'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTrialCard(context, 'U-14 Cricket Trial', 'Published', Colors.green),
          const SizedBox(height: 12),
          _buildTrialCard(context, 'U-16 Athletics Sprint', 'Draft', Colors.orange),
          const SizedBox(height: 12),
          _buildTrialCard(context, 'U-12 Swimming Trial', 'Closed', Colors.grey),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/post-trial'),
        icon: const Icon(Icons.add),
        label: const Text('New Trial'),
      ),
    );
  }

  Widget _buildTrialCard(BuildContext context, String title, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 12)),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'registrants', child: Text('View Registrants')),
              const PopupMenuItem(value: 'close', child: Text('Close')),
            ],
            onSelected: (value) {
              if (value == 'registrants') context.push('/registrant-list');
            },
          ),
        ],
      ),
    );
  }
}
