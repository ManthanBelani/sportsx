import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CapacityManagementScreen extends StatelessWidget {
  const CapacityManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Capacity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategoryCapacity(context, 'U-14 Category', 24, 18),
          const SizedBox(height: 24),
          _buildCategoryCapacity(context, 'U-16 Category', 24, 22),
          const SizedBox(height: 24),
          _buildCategoryCapacity(context, 'U-18 Category', 24, 9),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capacity settings saved')));
                context.pop();
              },
              child: const Text('Save Changes'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryCapacity(BuildContext context, String title, int totalSpots, int filled) {
    final fraction = filled / totalSpots;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Spots: $totalSpots'),
            Text('Filled: $filled'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: fraction,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          color: fraction > 0.9 ? Colors.red : Theme.of(context).primaryColor,
          backgroundColor: Colors.grey[200],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(value: false, onChanged: (v) {}),
            const Text('Enable waitlist when full'),
          ],
        )
      ],
    );
  }
}
