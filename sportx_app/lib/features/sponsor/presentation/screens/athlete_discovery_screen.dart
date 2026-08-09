import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AthleteDiscoveryScreen extends StatelessWidget {
  const AthleteDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Athletes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('Sport ▾'),
                const SizedBox(width: 8),
                _buildFilterChip('Age ▾'),
                const SizedBox(width: 8),
                _buildFilterChip('City ▾'),
                const SizedBox(width: 8),
                _buildFilterChip('Level ▾'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildAthleteCard(context, 'Aryan Patel', 'Cricket · U-14 · Ahmedabad', 2),
                const SizedBox(height: 12),
                _buildAthleteCard(context, 'Meera Shah', 'Badminton · U-16 · Surat', 1),
                const SizedBox(height: 12),
                _buildAthleteCard(context, 'Rohan Kumar', 'Football · U-14 · Mumbai', 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildAthleteCard(BuildContext context, String name, String subtitle, int achievements) {
    return InkWell(
      onTap: () => context.push('/athlete-profile-view'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text('🏆 $achievements achievements', style: const TextStyle(color: Colors.amber)),
                ],
              ),
            ),
            TextButton(onPressed: () => context.push('/athlete-profile-view'), child: const Text('View →')),
          ],
        ),
      ),
    );
  }
}
