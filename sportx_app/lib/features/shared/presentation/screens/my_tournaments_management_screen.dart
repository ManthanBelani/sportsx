import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyTournamentsManagementScreen extends StatelessWidget {
  const MyTournamentsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tournaments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTournamentCard(context, 'U-16 State Cup', 'Published', Colors.green),
          const SizedBox(height: 12),
          _buildTournamentCard(context, 'Inter-School Championship', 'Draft', Colors.orange),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/post-tournament'),
        icon: const Icon(Icons.add),
        label: const Text('New Tournament'),
      ),
    );
  }

  Widget _buildTournamentCard(BuildContext context, String title, String status, Color statusColor) {
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
              const PopupMenuItem(value: 'registrations', child: Text('Registrations')),
              const PopupMenuItem(value: 'results', child: Text('Results')),
            ],
            onSelected: (value) {
              if (value == 'registrations') context.push('/registration-management');
              if (value == 'results') context.push('/results-publishing');
            },
          ),
        ],
      ),
    );
  }
}
